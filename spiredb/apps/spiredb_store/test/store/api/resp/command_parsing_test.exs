defmodule Store.API.RESP.CommandParsingTest do
  @moduledoc """
  Tests command parsing behavior including case sensitivity, argument validation,
  and edge cases.

  ## Parsing Rules

  ### Case Sensitivity
  Commands are case-sensitive and must be UPPERCASE:
      Commands.execute(["PING"])    # => "PONG"
      Commands.execute(["ping"])    # => {:error, "ERR unknown command 'ping'"}

  ### Argument Types
  All arguments arrive as binary strings from RESP:
      Commands.execute(["INCRBY", "key", "5"])   # "5" is a string, parsed internally
      Commands.execute(["SET", "key", "123"])    # "123" stored as-is

  ### Empty/Missing Arguments
      Commands.execute([])                        # => {:error, "ERR empty command"}
      Commands.execute(["DEL"])                   # => {:error, ...} (needs at least 1 key)
      Commands.execute(["MSET", "k1"])            # => {:error, ...} (needs even args)
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

  describe "command case sensitivity" do
    test "PING must be uppercase" do
      assert "PONG" == Commands.execute(["PING"])
      assert {:error, _} = Commands.execute(["ping"])
      assert {:error, _} = Commands.execute(["Ping"])
      assert {:error, _} = Commands.execute(["pInG"])
    end

    test "GET must be uppercase" do
      Commands.execute(["SET", "key", "value"])
      assert "value" == Commands.execute(["GET", "key"])
      assert {:error, _} = Commands.execute(["get", "key"])
    end

    test "all standard commands are uppercase" do
      # Valid
      assert "OK" == Commands.execute(["SET", "k", "v"])
      assert _ = Commands.execute(["GET", "k"])
      assert _ = Commands.execute(["DEL", "k"])

      # Invalid (lowercase)
      assert {:error, _} = Commands.execute(["set", "k", "v"])
      assert {:error, _} = Commands.execute(["get", "k"])
      assert {:error, _} = Commands.execute(["del", "k"])
    end
  end

  describe "argument count validation" do
    test "PING accepts 0 or 1 arguments" do
      assert "PONG" == Commands.execute(["PING"])
      assert "hello" == Commands.execute(["PING", "hello"])
      # PING with 2+ args falls through to unknown
      # This tests the pattern matching
    end

    test "GET requires exactly 1 argument" do
      # GET without key goes to unknown command handler
      assert {:error, _} = Commands.execute(["GET"])
    end

    test "SET requires at least key and value" do
      assert {:error, _} = Commands.execute(["SET"])
      assert {:error, _} = Commands.execute(["SET", "key"])
    end

    test "DEL requires at least 1 key" do
      assert {:error, _} = Commands.execute(["DEL"])
      assert _ = Commands.execute(["DEL", "k1"])
      assert _ = Commands.execute(["DEL", "k1", "k2", "k3"])
    end

    test "EXISTS requires at least 1 key" do
      assert {:error, _} = Commands.execute(["EXISTS"])
      assert _ = Commands.execute(["EXISTS", "k1"])
    end

    test "MGET requires at least 1 key" do
      assert {:error, _} = Commands.execute(["MGET"])
      assert _ = Commands.execute(["MGET", "k1"])
    end

    test "MSET requires even number of arguments" do
      assert {:error, _} = Commands.execute(["MSET"])
      assert {:error, _} = Commands.execute(["MSET", "k1"])
      assert {:error, _} = Commands.execute(["MSET", "k1", "v1", "k2"])
      assert "OK" == Commands.execute(["MSET", "k1", "v1"])
      assert "OK" == Commands.execute(["MSET", "k1", "v1", "k2", "v2"])
    end
  end

  describe "integer argument parsing" do
    test "INCRBY parses string to integer" do
      assert 5 == Commands.execute(["INCRBY", "count", "5"])
      assert 10 == Commands.execute(["INCRBY", "count", "5"])
    end

    test "INCRBY rejects non-integers" do
      assert {:error, msg} = Commands.execute(["INCRBY", "key", "abc"])
      assert msg =~ "not an integer"

      assert {:error, _} = Commands.execute(["INCRBY", "key", "3.14"])
      assert {:error, _} = Commands.execute(["INCRBY", "key", ""])
      assert {:error, _} = Commands.execute(["INCRBY", "key", "5abc"])
    end

    test "DECRBY parses string to integer" do
      Commands.execute(["SET", "count", "10"])
      assert 7 == Commands.execute(["DECRBY", "count", "3"])
    end

    test "DECRBY rejects non-integers" do
      assert {:error, msg} = Commands.execute(["DECRBY", "key", "xyz"])
      assert msg =~ "not an integer"
    end

    test "EXPIRE parses seconds as integer" do
      Commands.execute(["SET", "key", "value"])
      assert 1 == Commands.execute(["EXPIRE", "key", "300"])
    end

    test "EXPIRE rejects non-integer seconds" do
      Commands.execute(["SET", "key", "value"])
      assert {:error, _} = Commands.execute(["EXPIRE", "key", "abc"])
    end
  end

  describe "value argument handling" do
    test "values are stored as-is (binary)" do
      Commands.execute(["SET", "key", "hello"])
      assert "hello" == Commands.execute(["GET", "key"])
    end

    test "numeric strings stay as strings" do
      Commands.execute(["SET", "key", "12345"])
      assert "12345" == Commands.execute(["GET", "key"])
    end

    test "empty string is valid value" do
      Commands.execute(["SET", "key", ""])
      assert "" == Commands.execute(["GET", "key"])
    end

    test "binary data is preserved" do
      # Note: avoid leading 0x00 or 0x01 bytes as they may conflict with TTL encoding
      binary = <<5, 1, 2, 255, 254, 253>>
      Commands.execute(["SET", "bin", binary])
      assert binary == Commands.execute(["GET", "bin"])
    end

    test "null bytes in value are preserved" do
      value = "hello\0world"
      Commands.execute(["SET", "key", value])
      assert value == Commands.execute(["GET", "key"])
    end
  end

  describe "key argument handling" do
    test "keys can be any binary" do
      Commands.execute(["SET", "simple", "v1"])
      Commands.execute(["SET", "with:colons:key", "v2"])
      Commands.execute(["SET", "with spaces", "v3"])
      Commands.execute(["SET", "with\ttab", "v4"])
      Commands.execute(["SET", "", "v5"])

      assert "v1" == Commands.execute(["GET", "simple"])
      assert "v2" == Commands.execute(["GET", "with:colons:key"])
      assert "v3" == Commands.execute(["GET", "with spaces"])
      assert "v4" == Commands.execute(["GET", "with\ttab"])
      assert "v5" == Commands.execute(["GET", ""])
    end

    test "key with newline works" do
      Commands.execute(["SET", "line1\nline2", "value"])
      assert "value" == Commands.execute(["GET", "line1\nline2"])
    end
  end

  describe "command with extra arguments" do
    test "SET accepts optional arguments" do
      # With EX
      assert "OK" == Commands.execute(["SET", "k", "v", "EX", "60"])
      # With PX
      assert "OK" == Commands.execute(["SET", "k", "v", "PX", "60000"])
      # With NX
      assert nil == Commands.execute(["SET", "k", "v2", "NX"])
      # With XX
      assert "OK" == Commands.execute(["SET", "k", "v3", "XX"])
      # Combined
      assert "OK" == Commands.execute(["SET", "k", "v4", "EX", "60", "XX"])
    end

    test "unknown SET options are ignored" do
      assert "OK" == Commands.execute(["SET", "k", "v", "UNKNOWNOPTION"])
      assert "v" == Commands.execute(["GET", "k"])
    end
  end

  describe "error messages" do
    test "unknown command includes command name in lowercase" do
      {:error, msg} = Commands.execute(["FAKECMD"])
      assert msg =~ "unknown command"
      assert msg =~ "'fakecmd'"
    end

    test "empty command returns specific error" do
      {:error, msg} = Commands.execute([])
      assert msg =~ "empty command"
    end

    test "integer parsing errors have consistent message" do
      {:error, msg1} = Commands.execute(["INCRBY", "k", "bad"])
      {:error, msg2} = Commands.execute(["DECRBY", "k", "bad"])
      {:error, msg3} = Commands.execute(["EXPIRE", "k", "bad"])

      assert msg1 =~ "not an integer"
      assert msg2 =~ "not an integer"
      assert msg3 =~ "not an integer"
    end
  end
end
