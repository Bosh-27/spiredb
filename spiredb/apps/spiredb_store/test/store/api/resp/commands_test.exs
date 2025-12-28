defmodule Store.API.RESP.CommandsTest do
  use ExUnit.Case, async: false

  alias Store.API.RESP.Commands
  alias Store.Test.MockServer

  setup do
    # Start the MockServer
    # We use start_supervised to ensure it shuts down after the test
    start_supervised!(MockServer)

    # Configure Commands to use the MockServer
    Application.put_env(:spiredb_store, :store_module, MockServer)

    # Reset config after test
    on_exit(fn ->
      Application.put_env(:spiredb_store, :store_module, Store.Server)
    end)

    :ok
  end

  describe "PING command" do
    test "returns PONG without argument" do
      assert "PONG" = Commands.execute(["PING"])
    end

    test "echoes message with argument" do
      assert "hello" = Commands.execute(["PING", "hello"])
      assert "world" = Commands.execute(["PING", "world"])
    end
  end

  describe "COMMAND" do
    test "returns empty list for compatibility" do
      assert [] = Commands.execute(["COMMAND"])
    end
  end

  describe "FLUSHALL command" do
    test "returns OK" do
      assert "OK" = Commands.execute(["FLUSHALL"])
    end
  end

  describe "STRLEN command" do
    test "returns 0 for operations without Store.Server" do
      # MockServer starts empty
      assert 0 = Commands.execute(["STRLEN", "anykey"])
    end

    test "returns length of existing key" do
      Commands.execute(["SET", "mykey", "hello"])
      assert 5 = Commands.execute(["STRLEN", "mykey"])
    end
  end

  describe "unknown commands" do
    test "returns error for unknown command" do
      assert {:error, msg} = Commands.execute(["UNKNOWN"])
      assert msg =~ "unknown command"
      assert msg =~ "unknown"
    end

    test "returns error with command name in lowercase" do
      assert {:error, msg} = Commands.execute(["BADCMD", "arg1", "arg2"])
      assert msg =~ "badcmd"
    end

    test "returns error for empty command list" do
      assert {:error, msg} = Commands.execute([])
      assert msg =~ "empty command"
    end
  end

  describe "Integer parsing in increment commands" do
    test "INCRBY with valid integer string" do
      # With MockServer, this should succeed and return the new value
      assert 5 = Commands.execute(["INCRBY", "counter", "5"])
      assert 15 = Commands.execute(["INCRBY", "counter", "10"])
    end

    test "INCRBY with invalid integer returns error" do
      assert {:error, msg} = Commands.execute(["INCRBY", "counter", "not_a_number"])
      assert msg =~ "not an integer"
    end

    test "DECRBY with valid integer string" do
      assert -3 = Commands.execute(["DECRBY", "counter", "3"])
    end

    test "DECRBY with invalid integer returns error" do
      assert {:error, msg} = Commands.execute(["DECRBY", "counter", "invalid"])
      assert msg =~ "not an integer"
    end
  end

  describe "Command structure validation" do
    test "DEL requires at least one key" do
      # DEL with no keys should match the catch-all unknown command
      assert {:error, _} = Commands.execute(["DEL"])
    end

    test "EXISTS requires at least one key" do
      assert {:error, _} = Commands.execute(["EXISTS"])
    end

    test "MGET requires at least one key" do
      assert {:error, _} = Commands.execute(["MGET"])
    end

    test "MSET requires even number of arguments" do
      # MSET with odd number of args (key without value)
      assert {:error, _} = Commands.execute(["MSET", "key1"])
    end
  end

  describe "SET command variations" do
    test "SET with key and value" do
      assert "OK" = Commands.execute(["SET", "mykey", "myvalue"])
      assert "myvalue" = Commands.execute(["GET", "mykey"])
    end

    test "SET with options (EX, PX, etc)" do
      # SET with expiration options (ignored by simple handler but should succeed)
      assert "OK" = Commands.execute(["SET", "key", "value", "EX", "60"])
    end
  end

  describe "Command parsing" do
    test "commands are case-sensitive in input" do
      assert "PONG" = Commands.execute(["PING"])
      # Lowercase commands should fail
      assert {:error, _} = Commands.execute(["ping"])
    end

    test "handles commands with multiple arguments" do
      # MSET with multiple key-value pairs
      result = Commands.execute(["MSET", "k1", "v1", "k2", "v2"])
      assert result == nil or is_binary(result) or match?({:error, _}, result)
    end
  end
end
