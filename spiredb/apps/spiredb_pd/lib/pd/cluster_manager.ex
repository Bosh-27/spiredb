defmodule PD.ClusterManager do
  @moduledoc """
  Manages PD cluster formation and joining logic.

  In a distributed environment (e.g. K8s), we need to distinguish between
  the "Seed" node (which bootstraps the Raft cluster) and "Joiner" nodes
  (which join the existing cluster).
  """

  use GenServer
  require Logger

  # Time to wait for libcluster to form mesh before deciding
  @initial_wait_ms 5_000
  @check_interval_ms 2_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    # Start checking logic
    Process.send_after(self(), :check_cluster_status, @initial_wait_ms)
    {:ok, %{joined: false, seed_node: nil}}
  end

  def handle_info(:check_cluster_status, state) do
    node_name = Node.self()
    pod_name = System.get_env("POD_NAME", "")

    # 1. Determine if I am the Seed Node
    is_seed = determine_if_seed(node_name, pod_name)

    # 2. Check if Raft is already running locally
    if raft_running?() do
      # Already running, nothing to do
      {:noreply, %{state | joined: true}}
    else
      if is_seed do
        bootstrap_cluster(node_name)
        {:noreply, %{state | joined: true}}
      else
        attempt_join(node_name, state)
      end
    end
  end

  defp bootstrap_cluster(node_name) do
    Logger.info("I am the Seed Node (#{node_name}). Bootstrapping PD cluster...")
    PD.Server.start_cluster(node_name)
  end

  defp attempt_join(node_name, state) do
    # Try to find the seed node in connected nodes
    nodes = Node.list()

    # In K8s, we might not know the exact node name of "-0", but we can try to guess or use standard naming if established.
    # However, creating a consistent 'initial_members' config for Raft is tricky if IPs change.

    # Better Strategy for non-seeds:
    # 1. Start a local Raft server that is *part* of a cluster defined by Seed.
    # But we can't start a server that points to a remote leader unless we have been added to config.

    # SO: We must ask the Seed to add us.
    # We need to find the Seed node in `Node.list()`.
    # Iterate nodes, RPC to check if they are leader?

    case find_leader_node(nodes) do
      {:ok, leader_node} ->
        Logger.info("Found PD Leader at #{leader_node}. Requesting to join...")

        case join_cluster(leader_node, node_name) do
          :ok ->
            Logger.info("Successfully joined cluster via #{leader_node}")
            # Now we start our local server?
            # Once added, the leader expects us to exist.
            # We should start our server *after* being added?
            # Or before?
            # Raft docs: "Start server, then add member."
            # But if we start server with [myself], we are leader.
            # If we start server with empty members?
            # `PD.Server.start_cluster_as_follower`?

            # Let's assume we start as empty/follower first.
            PD.Server.start_cluster_as_follower(node_name)
            {:noreply, %{state | joined: true}}

          {:error, reason} ->
            Logger.warning("Failed to join cluster: #{inspect(reason)}. Retrying...")
            schedule_check()
            {:noreply, state}
        end

      :no_leader ->
        Logger.info("No leader found yet. Waiting for cluster mesh...")
        schedule_check()
        {:noreply, state}
    end
  end

  defp find_leader_node(nodes) do
    # Ask each node if it is leader
    Enum.find_value(nodes, :no_leader, fn n ->
      try do
        # We can call a lightweight check
        # or check :ra.members({:pd_server, n})
        case :rpc.call(n, :ra, :leader, [{:pd_server, n}]) do
          # It knows a leader
          {:ok, _leader} -> {:ok, n}
          _ -> nil
        end
      catch
        _, _ -> nil
      end
    end)
  end

  defp join_cluster(leader_node, my_node) do
    # RPC to leader to add us
    # :ra.add_member(LeaderId, {MyServerId, MyNode})
    server_id = {:pd_server, my_node}
    leader_server = {:pd_server, leader_node}

    # Note: :ra.add_member must be called on a cluster member (preferably leader)
    case :rpc.call(leader_node, :ra, :add_member, [leader_server, {server_id, my_node}]) do
      {:ok, _, _} -> :ok
      err -> {:error, err}
    end
  end

  defp raft_running? do
    PD.Server.is_running?(Node.self())
  end

  defp determine_if_seed(node_name, pod_name) do
    # Explicit override always wins
    if System.get_env("SPIRE_IS_SEED") == "true",
      do: true,
      else: check_discovery_mode(node_name, pod_name)
  end

  defp check_discovery_mode(node_name, pod_name) do
    discovery = System.get_env("SPIRE_DISCOVERY", "epmd")

    case discovery do
      "k8sdns" ->
        # StatefulSet ordinal 0 is the seed
        String.ends_with?(pod_name, "-0")

      "epmd" ->
        # Static list: First node is the seed
        first_node =
          System.get_env("SPIRE_CLUSTER_NODES", "")
          |> String.split(",", trim: true)
          |> List.first()

        # Compare atoms or strings carefully
        if first_node do
          String.to_atom(first_node) == node_name
        else
          # Fallback for single node dev
          true
        end

      # Other modes (dns, gossip) must use explicit SPIRE_IS_SEED=true
      _ ->
        false
    end
  end

  defp schedule_check do
    Process.send_after(self(), :check_cluster_status, @check_interval_ms)
  end
end
