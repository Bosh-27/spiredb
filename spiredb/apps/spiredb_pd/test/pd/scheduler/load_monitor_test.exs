defmodule PD.Scheduler.LoadMonitorTest do
  use ExUnit.Case, async: true

  alias PD.Scheduler.LoadMonitor

  describe "collect_metrics/0" do
    test "returns metrics structure" do
      metrics = LoadMonitor.collect_metrics()

      assert is_map(metrics)
      assert Map.has_key?(metrics, :stores)
      assert Map.has_key?(metrics, :timestamp)
      assert Map.has_key?(metrics, :total_regions)
      assert is_list(metrics.stores)
    end

    test "calculates total regions correctly" do
      # This test will work once PD.Server is running
      metrics = LoadMonitor.collect_metrics()

      assert is_integer(metrics.total_regions)
      assert metrics.total_regions >= 0
    end
  end
end
