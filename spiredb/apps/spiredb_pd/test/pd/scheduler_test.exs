defmodule PD.SchedulerTest do
  use ExUnit.Case, async: false

  alias PD.Scheduler

  describe "scheduler lifecycle" do
    test "starts successfully" do
      {:ok, pid} = Scheduler.start_link([])

      assert Process.alive?(pid)

      # Cleanup
      GenServer.stop(pid)
    end

    test "returns stats" do
      {:ok, pid} = Scheduler.start_link([])

      stats = Scheduler.get_stats()

      assert is_map(stats)
      assert Map.has_key?(stats, :total_checks)
      assert Map.has_key?(stats, :total_operations)

      # Cleanup
      GenServer.stop(pid)
    end

    test "can trigger immediate check" do
      {:ok, pid} = Scheduler.start_link([])

      assert :ok = Scheduler.check_now()

      # Wait a bit for check to complete
      Process.sleep(100)

      stats = Scheduler.get_stats()
      assert stats.total_checks >= 1

      # Cleanup
      GenServer.stop(pid)
    end
  end
end
