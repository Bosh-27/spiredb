defmodule Store.API.RESP.ExpiryCommandsTest do
  @moduledoc """
  Tests for Redis TTL/expiry commands: TTL, PTTL, EXPIRE, PEXPIRE, EXPIREAT, PERSIST.

  ## Usage Examples

  ### TTL/PTTL
      Commands.execute(["SET", "key", "val", "EX", "300"])
      Commands.execute(["TTL", "key"])                   # => seconds remaining (e.g., 299)
      Commands.execute(["PTTL", "key"])                  # => milliseconds (e.g., 299000)
      Commands.execute(["TTL", "no_ttl_key"])            # => -1 (no expiry)
      Commands.execute(["TTL", "missing"])               # => -2 (key doesn't exist)

  ### EXPIRE/PEXPIRE
      Commands.execute(["SET", "key", "value"])
      Commands.execute(["EXPIRE", "key", "300"])         # => 1 (success)
      Commands.execute(["PEXPIRE", "key", "300000"])     # => 1 (300 seconds in ms)
      Commands.execute(["EXPIRE", "missing", "60"])      # => 0 (key doesn't exist)

  ### EXPIREAT
      Commands.execute(["EXPIREAT", "key", "1893456000"]) # => 1 (Unix timestamp)

  ### PERSIST
      Commands.execute(["PERSIST", "key"])               # => 1 (TTL removed)
      Commands.execute(["PERSIST", "no_ttl"])            # => 1 (already persistent)
      Commands.execute(["PERSIST", "missing"])           # => 0 (key doesn't exist)
  """
  use ExUnit.Case, async: false

  alias Store.API.RESP.Commands
  alias Store.Test.MockServer
  alias Store.KV.TTL

  setup do
    start_supervised!(MockServer)
    Application.put_env(:spiredb_store, :store_module, MockServer)

    on_exit(fn ->
      Application.put_env(:spiredb_store, :store_module, Store.Server)
    end)

    :ok
  end

  describe "TTL command" do
    test "returns -2 for non-existent key" do
      assert -2 == Commands.execute(["TTL", "missing"])
    end

    test "returns -1 for key without TTL" do
      # Basic SET doesn't encode with TTL wrapper in mock
      # Need to use the TTL module directly to test properly
      MockServer.put("no_ttl", TTL.encode_no_ttl("value"))
      assert -1 == Commands.execute(["TTL", "no_ttl"])
    end

    test "returns positive for key with TTL" do
      MockServer.put("ttl_key", TTL.encode_with_ttl("value", 300))
      remaining = Commands.execute(["TTL", "ttl_key"])
      assert remaining > 0
      assert remaining <= 300
    end
  end

  describe "PTTL command" do
    test "returns milliseconds" do
      MockServer.put("pttl_key", TTL.encode_with_ttl("value", 300))
      remaining = Commands.execute(["PTTL", "pttl_key"])
      # Should be roughly 300 * 1000
      assert remaining > 0
      assert remaining <= 300_000
    end

    test "returns -2000 for non-existent key" do
      # TTL is -2, PTTL multiplies by 1000
      assert -2000 == Commands.execute(["PTTL", "missing"])
    end
  end

  describe "EXPIRE command" do
    test "sets TTL on existing key" do
      MockServer.put("key", TTL.encode_no_ttl("value"))
      assert 1 == Commands.execute(["EXPIRE", "key", "300"])

      # Verify TTL was set
      remaining = Commands.execute(["TTL", "key"])
      assert remaining > 0
    end

    test "returns 0 for non-existent key" do
      assert 0 == Commands.execute(["EXPIRE", "missing", "60"])
    end

    test "returns error for invalid seconds" do
      MockServer.put("key", TTL.encode_no_ttl("value"))
      assert {:error, msg} = Commands.execute(["EXPIRE", "key", "not_a_number"])
      assert msg =~ "not an integer"
    end

    test "updates existing TTL" do
      MockServer.put("key", TTL.encode_with_ttl("value", 60))
      assert 1 == Commands.execute(["EXPIRE", "key", "300"])

      remaining = Commands.execute(["TTL", "key"])
      assert remaining > 60
    end
  end

  describe "PEXPIRE command" do
    test "sets TTL in milliseconds" do
      MockServer.put("key", TTL.encode_no_ttl("value"))
      assert 1 == Commands.execute(["PEXPIRE", "key", "60000"])

      remaining = Commands.execute(["TTL", "key"])
      assert remaining > 0
      assert remaining <= 60
    end

    test "returns error for invalid milliseconds" do
      assert {:error, msg} = Commands.execute(["PEXPIRE", "key", "invalid"])
      assert msg =~ "not an integer"
    end
  end

  describe "EXPIREAT command" do
    test "sets expiry to Unix timestamp" do
      MockServer.put("key", TTL.encode_no_ttl("value"))
      future_ts = System.system_time(:second) + 300
      assert 1 == Commands.execute(["EXPIREAT", "key", Integer.to_string(future_ts)])

      remaining = Commands.execute(["TTL", "key"])
      assert remaining > 0
      assert remaining <= 300
    end

    test "deletes key if timestamp is in the past" do
      MockServer.put("key", TTL.encode_no_ttl("value"))
      past_ts = System.system_time(:second) - 10
      assert 1 == Commands.execute(["EXPIREAT", "key", Integer.to_string(past_ts)])

      # Key should be deleted
      assert nil == Commands.execute(["GET", "key"])
    end

    test "returns error for invalid timestamp" do
      assert {:error, msg} = Commands.execute(["EXPIREAT", "key", "not_timestamp"])
      assert msg =~ "not an integer"
    end
  end

  describe "PERSIST command" do
    test "removes TTL from key" do
      MockServer.put("key", TTL.encode_with_ttl("value", 300))

      # Verify TTL exists
      assert Commands.execute(["TTL", "key"]) > 0

      assert 1 == Commands.execute(["PERSIST", "key"])

      # TTL should be -1 now
      assert -1 == Commands.execute(["TTL", "key"])
    end

    test "returns 0 for non-existent key" do
      assert 0 == Commands.execute(["PERSIST", "missing"])
    end

    test "value is preserved after PERSIST" do
      MockServer.put("key", TTL.encode_with_ttl("myvalue", 300))
      Commands.execute(["PERSIST", "key"])

      result = Commands.execute(["GET", "key"])
      assert result == "myvalue"
    end
  end

  describe "TTL expiration behavior" do
    test "expired key returns nil on GET" do
      # Manually create an expired value
      expiry_ts = System.system_time(:second) - 10
      encoded = <<0x01, expiry_ts::64-big, "expired_value">>
      MockServer.put("expired", encoded)

      assert nil == Commands.execute(["GET", "expired"])
    end

    test "TTL returns -2 for expired key" do
      expiry_ts = System.system_time(:second) - 10
      encoded = <<0x01, expiry_ts::64-big, "expired_value">>
      MockServer.put("expired", encoded)

      assert -2 == Commands.execute(["TTL", "expired"])
    end
  end
end
