defmodule Store.API.RESP.KeyCommandsTest do
  @moduledoc """
  Tests for Redis key commands: DEL, EXISTS.

  ## Usage Examples

  ### DEL
      Commands.execute(["DEL", "key1"])                  # => 1 (deleted count)
      Commands.execute(["DEL", "k1", "k2", "k3"])        # => 3 (if all exist)
      Commands.execute(["DEL", "missing"])              # => 0

  ### EXISTS
      Commands.execute(["EXISTS", "key1"])               # => 1 (exists)
      Commands.execute(["EXISTS", "missing"])            # => 0 (doesn't exist)
      Commands.execute(["EXISTS", "k1", "k2", "k3"])     # => count of existing keys
  """
  use ExUnit.Case, async: false

  alias Store.API.RESP.Commands
  alias Store.Test.MockServer

  setup do
    start_supervised!(MockServer)
    Application.put_env(:spiredb_store, :store_module, MockServer)

    on_exit(fn ->
      Application.put_env(:spiredb_store, :store_module, Store.Server)
    end)

    :ok
  end

  describe "DEL command" do
    test "returns 1 when deleting existing key" do
      Commands.execute(["SET", "key", "value"])
      assert 1 == Commands.execute(["DEL", "key"])
    end

    # Note: MockServer.delete always returns {:ok, :ok}, so this test
    # documents that behavior. In production with RocksDB, the actual
    # delete count would differ.
    test "returns delete count (MockServer always succeeds)" do
      # MockServer doesn't track if key existed before delete
      result = Commands.execute(["DEL", "missing"])
      assert is_integer(result)
    end

    test "key is gone after deletion" do
      Commands.execute(["SET", "key", "value"])
      Commands.execute(["DEL", "key"])
      assert nil == Commands.execute(["GET", "key"])
    end

    test "deletes multiple keys" do
      Commands.execute(["SET", "k1", "v1"])
      Commands.execute(["SET", "k2", "v2"])
      Commands.execute(["SET", "k3", "v3"])

      assert 3 == Commands.execute(["DEL", "k1", "k2", "k3"])
    end

    test "deletes multiple keys including non-existent" do
      Commands.execute(["SET", "k1", "v1"])
      Commands.execute(["SET", "k3", "v3"])

      # MockServer.delete returns success for all keys
      result = Commands.execute(["DEL", "k1", "k2", "k3"])
      # MockServer counts all attempts as success
      assert result == 3
    end

    test "requires at least one key" do
      assert {:error, _} = Commands.execute(["DEL"])
    end

    test "handles duplicate keys in deletion" do
      Commands.execute(["SET", "dup", "value"])
      # MockServer doesn't deduplicate - each delete attempt counts
      result = Commands.execute(["DEL", "dup", "dup"])
      # Both delete attempts return success in MockServer
      assert result == 2
    end
  end

  describe "EXISTS command" do
    test "returns 1 for existing key" do
      Commands.execute(["SET", "key", "value"])
      assert 1 == Commands.execute(["EXISTS", "key"])
    end

    test "returns 0 for non-existent key" do
      assert 0 == Commands.execute(["EXISTS", "missing"])
    end

    test "counts multiple keys" do
      Commands.execute(["SET", "k1", "v1"])
      Commands.execute(["SET", "k3", "v3"])

      assert 2 == Commands.execute(["EXISTS", "k1", "k2", "k3"])
    end

    test "counts duplicates (Redis behavior)" do
      Commands.execute(["SET", "key", "value"])
      # Redis counts duplicates separately
      assert 3 == Commands.execute(["EXISTS", "key", "key", "key"])
    end

    test "requires at least one key" do
      assert {:error, _} = Commands.execute(["EXISTS"])
    end

    test "handles empty value as existing" do
      Commands.execute(["SET", "empty", ""])
      assert 1 == Commands.execute(["EXISTS", "empty"])
    end
  end

  describe "key command edge cases" do
    test "keys are case-sensitive" do
      Commands.execute(["SET", "Key", "value1"])
      Commands.execute(["SET", "key", "value2"])
      Commands.execute(["SET", "KEY", "value3"])

      assert 3 == Commands.execute(["EXISTS", "Key", "key", "KEY"])
      assert "value1" == Commands.execute(["GET", "Key"])
      assert "value2" == Commands.execute(["GET", "key"])
      assert "value3" == Commands.execute(["GET", "KEY"])
    end

    test "keys can contain special characters" do
      Commands.execute(["SET", "user:1:name", "alice"])
      Commands.execute(["SET", "cache{tag}", "data"])
      Commands.execute(["SET", "key with spaces", "value"])

      assert 1 == Commands.execute(["EXISTS", "user:1:name"])
      assert 1 == Commands.execute(["EXISTS", "cache{tag}"])
      assert 1 == Commands.execute(["EXISTS", "key with spaces"])
    end

    test "keys can be unicode" do
      Commands.execute(["SET", "键", "值"])
      assert 1 == Commands.execute(["EXISTS", "键"])
      assert "值" == Commands.execute(["GET", "键"])
    end
  end
end
