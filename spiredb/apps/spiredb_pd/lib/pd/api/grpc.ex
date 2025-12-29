defmodule PD.API.GRPC do
  @moduledoc """
  gRPC service for Placement Driver metadata queries.

  Provides region discovery and routing information for SpireSQL
  to enable distributed scan operations.
  """

  use GRPC.Server, service: SpireDb.Spiredb.Pd.PlacementDriver.Service

  require Logger
  alias PD.Server

  alias SpireDb.Spiredb.Pd.{
    GetTableRegionsResponse,
    Region,
    RegisterStoreResponse,
    HeartbeatResponse
  }

  @doc """
  Get all regions for a table.
  """
  def get_table_regions(request, _stream) do
    Logger.debug("GetTableRegions", table: request.table_name)

    case Server.get_all_regions() do
      {:ok, regions} ->
        %GetTableRegionsResponse{
          regions: Enum.map(regions, &region_to_proto/1)
        }

      {:error, reason} ->
        Logger.error("GetTableRegions failed", reason: inspect(reason))

        raise GRPC.RPCError,
          status: :internal,
          message: "Failed to get regions: #{inspect(reason)}"
    end
  end

  @doc """
  Get region metadata for a key (Locate Region).
  """
  def get_region(request, _stream) do
    # Assuming GetRegion implies looking up where a key belongs
    # Since the request has a 'key' field and no 'region_id'
    Logger.debug("GetRegion", key: request.key)

    case Server.find_region(request.key) do
      {:ok, region} ->
        region_to_proto(region)

      {:error, :not_found} ->
        raise GRPC.RPCError, status: :not_found, message: "Region not found"

      {:error, reason} ->
        Logger.error("GetRegion failed", key: request.key, reason: inspect(reason))

        raise GRPC.RPCError,
          status: :internal,
          message: "Failed to locate region: #{inspect(reason)}"
    end
  end

  @doc """
  Register a store node with PD.
  """
  def register_store(request, _stream) do
    Logger.info("RegisterStore", node: request.node_name)

    case Server.register_store(request.node_name) do
      {:ok, _result, _leader} ->
        %RegisterStoreResponse{success: true}

      {:error, reason} ->
        Logger.error("RegisterStore failed", node: request.node_name, reason: inspect(reason))
        %RegisterStoreResponse{success: false}

      # Handle direct return if mocking/local
      {:ok, _result} ->
        %RegisterStoreResponse{success: true}
    end
  end

  @doc """
  Heartbeat from a store node.
  """
  def heartbeat(request, _stream) do
    Logger.debug("Heartbeat", node: request.node_name)

    case Server.heartbeat(request.node_name) do
      {:ok, :ok, _leader} ->
        %HeartbeatResponse{success: true}

      {:ok, {:error, reason}, _leader} ->
        Logger.warning("Heartbeat error from Raft",
          node: request.node_name,
          reason: inspect(reason)
        )

        %HeartbeatResponse{success: false}

      {:error, reason} ->
        Logger.warning("Heartbeat failed", node: request.node_name, reason: inspect(reason))
        %HeartbeatResponse{success: false}
    end
  end

  # Private helpers

  defp region_to_proto(region) do
    %Region{
      region_id: region.id,
      start_key: region.start_key || "",
      end_key: region.end_key || "",
      leader_node: to_string_safe(region.leader),
      followers: Enum.map(region.stores || [], &to_string/1),
      state: :REGION_STATE_ACTIVE
    }
  end

  defp to_string_safe(nil), do: ""
  defp to_string_safe(val) when is_atom(val), do: Atom.to_string(val)
  defp to_string_safe(val), do: to_string(val)
end
