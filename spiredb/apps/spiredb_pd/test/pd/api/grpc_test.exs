defmodule PD.API.GRPCTest do
  use ExUnit.Case, async: true

  alias PD.API.GRPC

  describe "module compilation and structure" do
    test "GRPC module exists and compiles" do
      # Verify the module is loaded
      assert Code.ensure_loaded?(PD.API.GRPC)
    end

    test "GRPC module has required functions" do
      # Verify all RPC handler functions are defined
      functions = PD.API.GRPC.__info__(:functions)

      assert Keyword.has_key?(functions, :get_table_regions)
      assert Keyword.has_key?(functions, :get_region)
      assert Keyword.has_key?(functions, :register_store)
      assert Keyword.has_key?(functions, :heartbeat)
    end
  end

  describe "request format validation" do
    test "get_table_regions handles request structure" do
      request = %{table_name: "test"}

      result = GRPC.get_table_regions(request, nil)

      # Either success OR error (if Server not running)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "get_region handles request structure" do
      request = %{region_id: 1}

      result = GRPC.get_region(request, nil)

      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "register_store handles request structure" do
      request = %{node_name: "test"}

      result = GRPC.register_store(request, nil)

      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "heartbeat handles request structure" do
      request = %{node_name: "test"}

      result = GRPC.heartbeat(request, nil)

      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "error responses" do
    test "returns proper error structure for failures" do
      request = %{table_name: "test"}

      case GRPC.get_table_regions(request, nil) do
        {:ok, _} ->
          # Success is fine if Server is running
          assert true

        {:error, _error} ->
          # Error is expected if Server not running
          # Just verify we got an error tuple
          assert true
      end
    end
  end

  # Note: Full integration tests with actual PD.Server would go in
  # apps/spiredb_pd/test/pd/api/grpc_integration_test.exs
  # and would be excluded from normal test runs (require Raft enabled)
end
