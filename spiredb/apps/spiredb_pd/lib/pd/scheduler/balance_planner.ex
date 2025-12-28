defmodule PD.Scheduler.BalancePlanner do
  @moduledoc """
  Computes rebalancing operations for optimal region distribution.

  Strategies:
  - Even distribution: Spread regions evenly across alive stores
  - Replica placement: Ensure target replicas per region (future)
  - Failure recovery: Replace failed stores (future)
  """

  require Logger

  @target_replicas 3
  # Trigger rebalance if difference > 2 regions
  @imbalance_threshold 2

  @doc """
  Compute a rebalancing plan based on current metrics.

  Returns a plan with:
  - operations: list of operations to execute
  - reason: why operations are needed (or :skip)
  - timestamp: when plan was computed
  """
  def compute_plan(metrics, active_operations \\ []) do
    if should_skip_planning?(metrics, active_operations) do
      %{operations: [], reason: :skip, timestamp: DateTime.utc_now()}
    else
      operations =
        []
        |> maybe_add_balance_operations(metrics)
        |> maybe_add_replica_operations(metrics)
        |> maybe_add_recovery_operations(metrics)

      %{
        operations: operations,
        reason: if(operations == [], do: :balanced, else: :rebalance_needed),
        timestamp: DateTime.utc_now(),
        metrics_snapshot: metrics
      }
    end
  end

  defp should_skip_planning?(_metrics, active_ops) do
    # Skip if operations already in progress
    length(active_ops) > 0
  end

  defp maybe_add_balance_operations(ops, metrics) do
    alive_stores = Enum.filter(metrics.stores, & &1.is_alive)

    if length(alive_stores) < 2 do
      # Need at least 2 stores to balance
      ops
    else
      region_counts = Enum.map(alive_stores, & &1.region_count)
      max_count = Enum.max(region_counts)
      min_count = Enum.min(region_counts)

      if max_count - min_count > @imbalance_threshold do
        # Cluster is imbalanced
        overloaded = Enum.find(alive_stores, &(&1.region_count == max_count))
        underloaded = Enum.find(alive_stores, &(&1.region_count == min_count))

        Logger.info("Cluster imbalanced - planning rebalance",
          max: max_count,
          min: min_count,
          from: overloaded.node,
          to: underloaded.node
        )

        # Select a region to move
        region_to_move = select_region_to_move(overloaded)

        if region_to_move do
          [
            %{
              type: :move_region,
              region_id: region_to_move,
              from_store: overloaded.node,
              to_store: underloaded.node,
              reason: :balance,
              priority: :normal
            }
            | ops
          ]
        else
          ops
        end
      else
        # Cluster is balanced
        ops
      end
    end
  end

  defp maybe_add_replica_operations(ops, metrics) do
    # Check each region has target number of replicas
    alive_stores = Enum.filter(metrics.stores, & &1.is_alive)

    if length(alive_stores) < @target_replicas do
      # Not enough stores for target replicas
      Logger.debug("Insufficient stores for target replicas",
        alive: length(alive_stores),
        target: @target_replicas
      )

      ops
    else
      # For now, replica management is handled by future region metadata
      # This would require tracking which stores have which replicas per region
      # Stub: Ready for implementation when region replica tracking is added
      ops
    end
  end

  defp maybe_add_recovery_operations(ops, metrics) do
    # Detect failed stores and create recovery operations
    dead_stores = Enum.filter(metrics.stores, &(!&1.is_alive))
    alive_stores = Enum.filter(metrics.stores, & &1.is_alive)

    if length(dead_stores) > 0 and length(alive_stores) > 0 do
      Logger.debug("Failed stores detected - planning recovery",
        dead: length(dead_stores),
        alive: length(alive_stores)
      )

      # Create recovery operations for each region on dead stores
      recovery_ops =
        for dead_store <- dead_stores,
            region_id <- dead_store.regions || [] do
          # Pick a random alive store to take over this region
          target_store = Enum.random(alive_stores)

          %{
            type: :move_region,
            region_id: region_id,
            from_store: dead_store.node,
            to_store: target_store.node,
            reason: :recovery,
            # Recovery has higher priority than balancing
            priority: :high
          }
        end

      ops ++ recovery_ops
    else
      ops
    end
  end

  defp select_region_to_move(store) do
    # Simple strategy: pick first region
    # Future: Pick least active region, smallest region, etc.
    regions = store.regions || []

    if length(regions) > 0 do
      hd(regions)
    else
      nil
    end
  end
end
