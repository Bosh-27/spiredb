defmodule PD.Server do
  @moduledoc """
  Placement Driver server using Raft consensus.

  Manages cluster metadata:
  - Store registry (which nodes are alive)
  - Region assignments (which stores host which regions)
  - Key-to-region routing
  """

  @behaviour :ra_machine

  require Logger

  alias PD.Types.{Region, Store}

  @type state :: %{
          stores: %{atom() => Store.t()},
          regions: %{non_neg_integer() => Region.t()},
          next_region_id: non_neg_integer(),
          num_regions: non_neg_integer()
        }

  ## Ra Machine Callbacks

  @impl :ra_machine
  def init(_config) do
    num_regions = Application.get_env(:spiredb_pd, :num_regions, 16)

    state = %{
      stores: %{},
      regions: %{},
      next_region_id: 1,
      num_regions: num_regions
    }

    # Ra machine init must return state
    state
  end

  @impl :ra_machine
  def apply(_meta, {:register_store, node_name}, state) do
    if Map.has_key?(state.stores, node_name) do
      Logger.info("Store re-registered: #{node_name}")
    else
      Logger.info("New store joined cluster: #{node_name}")
    end

    store = %Store{
      node: node_name,
      regions: [],
      last_heartbeat: DateTime.utc_now(),
      state: :up
    }

    new_state = %{state | stores: Map.put(state.stores, node_name, store)}

    # Return: {new_state, reply, effects}
    {new_state, {:ok, node_name}, []}
  end

  @impl :ra_machine
  def apply(_meta, {:heartbeat, node_name}, state) do
    case Map.get(state.stores, node_name) do
      nil ->
        {state, {:error, :store_not_found}, []}

      store ->
        updated_store = %{store | last_heartbeat: DateTime.utc_now()}
        new_state = %{state | stores: Map.put(state.stores, node_name, updated_store)}
        {new_state, :ok, []}
    end
  end

  @impl :ra_machine
  def apply(_meta, {:create_region, region_params}, state) do
    region = %Region{
      id: state.next_region_id,
      start_key: region_params[:start_key],
      end_key: region_params[:end_key],
      stores: region_params[:stores] || [],
      epoch: 1,
      leader: nil
    }

    new_state = %{
      state
      | regions: Map.put(state.regions, region.id, region),
        next_region_id: state.next_region_id + 1
    }

    {new_state, {:ok, region}, []}
    {new_state, {:ok, region}, []}
  end

  @impl :ra_machine
  def state_enter(_ra_state, _machine_state), do: []

  ## Query Functions (read-only, don't modify state)

  def find_region_by_key(state, key) do
    # Simple hash-based routing
    region_id = :erlang.phash2(key, state.num_regions) + 1
    Map.get(state.regions, region_id)
  end

  def list_stores(state) do
    Map.values(state.stores)
  end

  def get_region(state, region_id) do
    Map.get(state.regions, region_id)
  end

  ## Public API (to be called via Ra)

  @doc """
  Start the PD Raft cluster.
  """
  @doc """
  Start the PD Raft server as a follower (empty initial members).
  Used by non-seed nodes joining an existing cluster.
  """
  def start_cluster_as_follower(node_name) do
    start_cluster(node_name, [])
  end

  @doc """
  Check if local Raft server is running.
  """
  def is_running?(node_name) do
    case :ra.members({:pd_server, node_name}) do
      {:ok, _, _} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  def start_cluster(node_name) do
    # Default to single-node bootstrap
    server_id = {:pd_server, node_name}
    start_cluster(node_name, [server_id])
  end

  def start_cluster(node_name, initial_members) do
    server_id = {:pd_server, node_name}
    cluster_name = :pd_cluster
    machine = {:module, __MODULE__, %{}}

    wait_for_ra_system(150)

    sanitized_name = node_name |> to_string() |> String.replace(~r/[^a-zA-Z0-9_-]/, "_")

    config = %{
      id: server_id,
      uid: "pd_#{sanitized_name}",
      cluster_name: cluster_name,
      machine: machine,
      initial_members: initial_members,
      log_init_args: %{},
      wal_max_size_bytes: 64 * 1024 * 1024,
      wal_pre_allocate: true,
      wal_write_strategy: :o_sync,
      segment_max_entries: 32768,
      snapshot_interval: 4096
    }

    start_cluster_with_retry(node_name, config)
  end

  defp start_cluster_with_retry(node_name, config, retries \\ 30) do
    Logger.info("Calling :ra.start_server for PD server...")

    try do
      case :ra.start_server(:default, config) do
        :ok ->
          Logger.info("PD Raft server started successfully.")
          :ok

        {:error, :already_started} ->
          :ok

        {:error, reason} ->
          retry_start(node_name, config, retries, reason)
      end
    catch
      :exit, reason ->
        retry_start(node_name, config, retries, reason)
    end
  end

  defp retry_start(node_name, config, retries, reason) do
    if retries > 0 do
      Process.sleep(500)
      start_cluster_with_retry(node_name, config, retries - 1)
    else
      raise "Failed to start PD Raft server: #{inspect(reason)}"
    end
  end

  @doc """
  Register a store node.
  """
  def register_store(node_name) do
    :ra.process_command({:pd_server, node()}, {:register_store, node_name})
  end

  @doc """
  Send heartbeat from a store.
  """
  def heartbeat(node_name) do
    :ra.process_command({:pd_server, node()}, {:heartbeat, node_name})
  end

  @doc """
  Create a new region.
  """
  def create_region(params) do
    :ra.process_command({:pd_server, node()}, {:create_region, params})
  end

  @doc """
  Find which region a key belongs to.
  """
  def find_region(key) do
    # Query the current state
    case :ra.leader_query({:pd_server, node()}, &find_region_by_key(&1, key)) do
      {:ok, {_index, region}, _leader} -> {:ok, region}
      {:error, _} = error -> error
      {:timeout, _} -> {:error, :timeout}
    end
  end

  @doc """
  Get all regions (for distributed scans).

  Returns list of all regions for SpireSQL to fan out queries.
  """
  def get_all_regions do
    case :ra.leader_query({:pd_server, node()}, &list_all_regions/1) do
      {:ok, {_index, regions}, _leader} -> {:ok, regions}
      {:error, _} = error -> error
      {:timeout, _} -> {:error, :timeout}
    end
  end

  @doc """
  Get region by ID.
  """
  def get_region_by_id(region_id) do
    case :ra.leader_query({:pd_server, node()}, &get_region(&1, region_id)) do
      {:ok, {_index, region}, _leader} -> {:ok, region}
      {:error, _} = error -> error
      {:timeout, _} -> {:error, :timeout}
    end
  end

  defp list_all_regions(state) do
    Map.values(state.regions)
  end

  defp wait_for_ra_system(retries \\ 150) do
    if retries == 0 do
      raise "Ra system failed to become ready"
    else
      # Check if Ra application supervisor is running
      # Note: :ra 2.x doesn't register :ra_directory globally in the same way
      # so we rely on :ra_sup existence and the explicit start_default call
      if Process.whereis(:ra_sup) do
        :ok
      else
        Process.sleep(100)
        wait_for_ra_system(retries - 1)
      end
    end
  end
end
