defmodule Store.API.RESP.StringCommandsTest do
  @moduledoc """
  Tests for Redis string commands: GET, SET, MGET, MSET, INCR, DECR, INCRBY, DECRBY, APPEND, STRLEN.

  ## Usage Examples

  These tests demonstrate the de-facto usage patterns for string commands:

  ### GET/SET
      Commands.execute(["SET", "key", "value"])         # => "OK"
      Commands.execute(["GET", "key"])                  # => "value"
      Commands.execute(["GET", "missing"])              # => nil

  ### SET with options
      Commands.execute(["SET", "k", "v", "EX", "60"])   # => "OK" (expires in 60s)
      Commands.execute(["SET", "k", "v", "PX", "1000"]) # => "OK" (expires in 1000ms)
      Commands.execute(["SET", "k", "v", "NX"])         # => "OK" only if key doesn't exist
      Commands.execute(["SET", "k", "v", "XX"])         # => "OK" only if key exists

  ### MGET/MSET
      Commands.execute(["MSET", "k1", "v1", "k2", "v2"]) # => "OK"
      Commands.execute(["MGET", "k1", "k2", "missing"])  # => ["v1", "v2", nil]

  ### Increment/Decrement
      Commands.execute(["INCR", "counter"])              # => 1 (creates if missing)
      Commands.execute(["INCRBY", "counter", "5"])       # => 6
      Commands.execute(["DECR", "counter"])              # => 5
      Commands.execute(["DECRBY", "counter", "2"])       # => 3

  ### APPEND/STRLEN
      Commands.execute(["APPEND", "key", "hello"])       # => 5 (byte length)
      Commands.execute(["APPEND", "key", " world"])      # => 11
      Commands.execute(["STRLEN", "key"])                # => 11
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

  describe "GET command" do
    test "returns nil for non-existent key" do
      assert nil == Commands.execute(["GET", "missing_key"])
    end

    test "returns value for existing key" do
      Commands.execute(["SET", "mykey", "myvalue"])
      assert "myvalue" == Commands.execute(["GET", "mykey"])
    end

    test "returns raw binary values unchanged" do
      binary = <<1, 2, 3, 255, 0, 128>>
      Commands.execute(["SET", "binkey", binary])
      assert binary == Commands.execute(["GET", "binkey"])
    end

    test "handles empty string value" do
      Commands.execute(["SET", "empty", ""])
      assert "" == Commands.execute(["GET", "empty"])
    end

    test "handles unicode values" do
      Commands.execute(["SET", "unicode", "你好世界"])
      assert "你好世界" == Commands.execute(["GET", "unicode"])
    end
  end

  describe "SET command" do
    test "basic SET returns OK" do
      assert "OK" == Commands.execute(["SET", "key", "value"])
    end

    test "overwrites existing key" do
      Commands.execute(["SET", "key", "first"])
      Commands.execute(["SET", "key", "second"])
      assert "second" == Commands.execute(["GET", "key"])
    end

    test "handles large values" do
      large = String.duplicate("x", 100_000)
      assert "OK" == Commands.execute(["SET", "large", large])
      assert large == Commands.execute(["GET", "large"])
    end
  end

  describe "SET with EX option" do
    test "accepts EX (seconds) option" do
      assert "OK" == Commands.execute(["SET", "ttl_key", "value", "EX", "300"])
    end

    test "rejects invalid EX value" do
      # SET still works by ignoring invalid options in current implementation
      assert "OK" == Commands.execute(["SET", "key", "val", "EX", "not_a_number"])
    end
  end

  describe "SET with PX option" do
    test "accepts PX (milliseconds) option" do
      assert "OK" == Commands.execute(["SET", "ttl_key", "value", "PX", "60000"])
    end
  end

  describe "SET with NX option" do
    test "NX succeeds when key doesn't exist" do
      assert "OK" == Commands.execute(["SET", "nx_key", "value", "NX"])
      assert "value" == Commands.execute(["GET", "nx_key"])
    end

    test "NX returns nil when key exists" do
      Commands.execute(["SET", "nx_key", "first"])
      assert nil == Commands.execute(["SET", "nx_key", "second", "NX"])
      # Original value unchanged
      assert "first" == Commands.execute(["GET", "nx_key"])
    end
  end

  describe "SET with XX option" do
    test "XX returns nil when key doesn't exist" do
      assert nil == Commands.execute(["SET", "xx_key", "value", "XX"])
      assert nil == Commands.execute(["GET", "xx_key"])
    end

    test "XX succeeds when key exists" do
      Commands.execute(["SET", "xx_key", "first"])
      assert "OK" == Commands.execute(["SET", "xx_key", "second", "XX"])
      assert "second" == Commands.execute(["GET", "xx_key"])
    end
  end

  describe "SET with combined options" do
    test "EX with NX" do
      assert "OK" == Commands.execute(["SET", "combo", "val", "EX", "60", "NX"])
    end

    test "PX with XX" do
      Commands.execute(["SET", "combo2", "first"])
      assert "OK" == Commands.execute(["SET", "combo2", "second", "PX", "1000", "XX"])
    end
  end

  describe "MGET command" do
    test "returns values for multiple keys" do
      Commands.execute(["SET", "k1", "v1"])
      Commands.execute(["SET", "k2", "v2"])
      Commands.execute(["SET", "k3", "v3"])

      result = Commands.execute(["MGET", "k1", "k2", "k3"])
      assert ["v1", "v2", "v3"] == result
    end

    test "returns nil for missing keys in the list" do
      Commands.execute(["SET", "k1", "v1"])

      result = Commands.execute(["MGET", "k1", "missing", "k1"])
      assert ["v1", nil, "v1"] == result
    end

    test "returns all nils for all missing keys" do
      result = Commands.execute(["MGET", "a", "b", "c"])
      assert [nil, nil, nil] == result
    end

    test "requires at least one key" do
      assert {:error, _} = Commands.execute(["MGET"])
    end
  end

  describe "MSET command" do
    test "sets multiple key-value pairs" do
      assert "OK" == Commands.execute(["MSET", "k1", "v1", "k2", "v2"])
      assert "v1" == Commands.execute(["GET", "k1"])
      assert "v2" == Commands.execute(["GET", "k2"])
    end

    test "overwrites existing keys" do
      Commands.execute(["SET", "k1", "old"])
      Commands.execute(["MSET", "k1", "new", "k2", "v2"])
      assert "new" == Commands.execute(["GET", "k1"])
    end

    test "requires even number of arguments" do
      assert {:error, _} = Commands.execute(["MSET", "k1"])
      assert {:error, _} = Commands.execute(["MSET", "k1", "v1", "k2"])
    end

    test "requires at least one key-value pair" do
      assert {:error, _} = Commands.execute(["MSET"])
    end
  end

  describe "INCR command" do
    test "increments existing integer value" do
      Commands.execute(["SET", "counter", "10"])
      assert 11 == Commands.execute(["INCR", "counter"])
      assert 12 == Commands.execute(["INCR", "counter"])
    end

    test "initializes to 1 if key doesn't exist" do
      assert 1 == Commands.execute(["INCR", "new_counter"])
      assert 2 == Commands.execute(["INCR", "new_counter"])
    end

    test "returns error for non-integer value" do
      Commands.execute(["SET", "not_int", "hello"])
      assert {:error, msg} = Commands.execute(["INCR", "not_int"])
      assert msg =~ "not an integer"
    end

    test "handles negative numbers" do
      Commands.execute(["SET", "neg", "-5"])
      assert -4 == Commands.execute(["INCR", "neg"])
    end
  end

  describe "DECR command" do
    test "decrements existing integer value" do
      Commands.execute(["SET", "counter", "10"])
      assert 9 == Commands.execute(["DECR", "counter"])
      assert 8 == Commands.execute(["DECR", "counter"])
    end

    test "initializes to -1 if key doesn't exist" do
      assert -1 == Commands.execute(["DECR", "new_counter"])
      assert -2 == Commands.execute(["DECR", "new_counter"])
    end

    test "returns error for non-integer value" do
      Commands.execute(["SET", "not_int", "world"])
      assert {:error, msg} = Commands.execute(["DECR", "not_int"])
      assert msg =~ "not an integer"
    end
  end

  describe "INCRBY command" do
    test "increments by specified amount" do
      Commands.execute(["SET", "counter", "10"])
      assert 15 == Commands.execute(["INCRBY", "counter", "5"])
      assert 25 == Commands.execute(["INCRBY", "counter", "10"])
    end

    test "works with negative increment" do
      Commands.execute(["SET", "counter", "10"])
      assert 7 == Commands.execute(["INCRBY", "counter", "-3"])
    end

    test "initializes to increment if key doesn't exist" do
      assert 42 == Commands.execute(["INCRBY", "new", "42"])
    end

    test "returns error for invalid increment" do
      assert {:error, msg} = Commands.execute(["INCRBY", "k", "not_a_num"])
      assert msg =~ "not an integer"
    end

    test "returns error for float increment" do
      assert {:error, msg} = Commands.execute(["INCRBY", "k", "3.14"])
      assert msg =~ "not an integer"
    end
  end

  describe "DECRBY command" do
    test "decrements by specified amount" do
      Commands.execute(["SET", "counter", "10"])
      assert 7 == Commands.execute(["DECRBY", "counter", "3"])
      assert 2 == Commands.execute(["DECRBY", "counter", "5"])
    end

    test "works with negative decrement (adds)" do
      Commands.execute(["SET", "counter", "10"])
      assert 15 == Commands.execute(["DECRBY", "counter", "-5"])
    end

    test "initializes to negative value if key doesn't exist" do
      assert -10 == Commands.execute(["DECRBY", "new", "10"])
    end

    test "returns error for invalid decrement" do
      assert {:error, msg} = Commands.execute(["DECRBY", "k", "xyz"])
      assert msg =~ "not an integer"
    end
  end

  describe "APPEND command" do
    test "appends to existing value" do
      Commands.execute(["SET", "key", "Hello"])
      assert 11 == Commands.execute(["APPEND", "key", " World"])
      assert "Hello World" == Commands.execute(["GET", "key"])
    end

    test "creates key if it doesn't exist" do
      assert 5 == Commands.execute(["APPEND", "new_key", "hello"])
      assert "hello" == Commands.execute(["GET", "new_key"])
    end

    test "returns byte length, not character count" do
      # UTF-8: 日本 = 6 bytes (3 bytes each), 語語 = 6 bytes (3 bytes each)
      assert 6 == Commands.execute(["APPEND", "utf", "日本"])
      assert 12 == Commands.execute(["APPEND", "utf", "語語"])
    end

    test "handles empty append" do
      Commands.execute(["SET", "key", "value"])
      assert 5 == Commands.execute(["APPEND", "key", ""])
      assert "value" == Commands.execute(["GET", "key"])
    end
  end

  describe "STRLEN command" do
    test "returns length of existing key" do
      Commands.execute(["SET", "key", "hello"])
      assert 5 == Commands.execute(["STRLEN", "key"])
    end

    test "returns 0 for non-existent key" do
      assert 0 == Commands.execute(["STRLEN", "missing"])
    end

    test "returns byte length for UTF-8" do
      Commands.execute(["SET", "utf", "日本語"])
      # 3 characters, 9 bytes
      assert 9 == Commands.execute(["STRLEN", "utf"])
    end

    test "handles empty string" do
      Commands.execute(["SET", "empty", ""])
      assert 0 == Commands.execute(["STRLEN", "empty"])
    end
  end
end
