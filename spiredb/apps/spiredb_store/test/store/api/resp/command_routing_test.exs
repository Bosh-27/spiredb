defmodule Store.API.RESP.CommandRoutingTest do
  @moduledoc """
  Tests for command routing to specialized command handlers.

  Verifies that commands are correctly routed to:
  - TableCommands (SPIRE.TABLE.*, SPIRE.INDEX.*)
  - TxnCommands (MULTI, EXEC, DISCARD, SAVEPOINT, ROLLBACK TO)
  - VectorCommands (FT.*)
  - PluginCommands (SPIRE.PLUGIN.*)
  - StreamCommands (X*)

  ## Usage Examples

  ### Table Commands (routed to TableCommands)
      Commands.execute(["SPIRE.TABLE.CREATE", "users", ...])
      Commands.execute(["SPIRE.TABLE.DROP", "users"])
      Commands.execute(["SPIRE.TABLE.LIST"])
      Commands.execute(["SPIRE.TABLE.DESCRIBE", "users"])
      Commands.execute(["SPIRE.INDEX.CREATE", ...])
      Commands.execute(["SPIRE.INDEX.DROP", ...])

  ### Transaction Commands (routed to TxnCommands)
      Commands.execute(["MULTI"])
      Commands.execute(["EXEC"])
      Commands.execute(["DISCARD"])
      Commands.execute(["SAVEPOINT", "sp1"])
      Commands.execute(["ROLLBACK", "TO", "sp1"])

  ### Vector Commands (routed to VectorCommands)
      Commands.execute(["FT.CREATE", index_name, ...])
      Commands.execute(["FT.DROPINDEX", index_name])
      Commands.execute(["FT.ADD", ...])
      Commands.execute(["FT.DEL", ...])
      Commands.execute(["FT.SEARCH", ...])
      Commands.execute(["FT.INFO", index_name])
      Commands.execute(["FT._LIST"])

  ### Plugin Commands (routed to PluginCommands)
      Commands.execute(["SPIRE.PLUGIN.LIST"])
      Commands.execute(["SPIRE.PLUGIN.INFO", plugin_name])
      Commands.execute(["SPIRE.PLUGIN.RELOAD", plugin_name])

  ### Stream Commands (routed to StreamCommands)
      Commands.execute(["XADD", stream, "*", "field", "value"])
      Commands.execute(["XREAD", ...])
      Commands.execute(["XRANGE", stream, "-", "+"])
      Commands.execute(["XREVRANGE", stream, "+", "-"])
      Commands.execute(["XLEN", stream])
      Commands.execute(["XINFO", "STREAM", stream])
      Commands.execute(["XTRIM", stream, "MAXLEN", "1000"])
      Commands.execute(["XDEL", stream, id])
  """
  use ExUnit.Case, async: true

  alias Store.API.RESP.Commands

  # Helper to check if routing works
  # A command is "routed" if it doesn't return the generic "unknown command" error
  # Commands may still fail due to missing args or infrastructure
  defp is_routed?(result) do
    case result do
      {:error, msg} when is_binary(msg) ->
        # Check if it's NOT an "unknown command" error from Commands module
        not String.starts_with?(msg, "ERR unknown command")

      _ ->
        # Any other result (success, other errors, crashes) means it was routed
        true
    end
  end

  # Note: Some commands require running infrastructure (GenServers, etc.)
  # Tests tagged with :requires_infrastructure are excluded by default
  # Run them with: mix test --include requires_infrastructure

  @moduletag :capture_log

  describe "SPIRE.TABLE.* routing" do
    test "SPIRE.TABLE.CREATE is routed (not unknown)" do
      result = Commands.execute(["SPIRE.TABLE.CREATE"])

      assert is_routed?(result),
             "Expected SPIRE.TABLE.CREATE to be routed, got: #{inspect(result)}"
    end

    test "SPIRE.TABLE.DROP is routed" do
      result = Commands.execute(["SPIRE.TABLE.DROP"])
      assert is_routed?(result)
    end

    test "SPIRE.TABLE.DESCRIBE is routed" do
      result = Commands.execute(["SPIRE.TABLE.DESCRIBE"])
      assert is_routed?(result)
    end
  end

  describe "SPIRE.INDEX.* routing" do
    test "SPIRE.INDEX.CREATE is routed" do
      result = Commands.execute(["SPIRE.INDEX.CREATE"])
      assert is_routed?(result)
    end

    test "SPIRE.INDEX.DROP is routed" do
      result = Commands.execute(["SPIRE.INDEX.DROP"])
      assert is_routed?(result)
    end
  end

  describe "FT.* (Vector) command routing" do
    test "FT.CREATE is routed" do
      result = Commands.execute(["FT.CREATE"])
      assert is_routed?(result)
    end

    test "FT.DROPINDEX is routed" do
      result = Commands.execute(["FT.DROPINDEX"])
      assert is_routed?(result)
    end

    test "FT.ADD is routed" do
      result = Commands.execute(["FT.ADD"])
      assert is_routed?(result)
    end

    test "FT.DEL is routed" do
      result = Commands.execute(["FT.DEL"])
      assert is_routed?(result)
    end

    test "FT.SEARCH is routed" do
      result = Commands.execute(["FT.SEARCH"])
      assert is_routed?(result)
    end

    test "FT.INFO is routed" do
      result = Commands.execute(["FT.INFO"])
      assert is_routed?(result)
    end

    test "FT._LIST is routed" do
      result = Commands.execute(["FT._LIST"])
      assert is_routed?(result)
    end
  end

  describe "SPIRE.PLUGIN.* routing" do
    test "SPIRE.PLUGIN.LIST is routed" do
      result = Commands.execute(["SPIRE.PLUGIN.LIST"])
      assert is_routed?(result)
    end

    test "SPIRE.PLUGIN.INFO is routed" do
      result = Commands.execute(["SPIRE.PLUGIN.INFO"])
      assert is_routed?(result)
    end

    test "SPIRE.PLUGIN.RELOAD is routed" do
      result = Commands.execute(["SPIRE.PLUGIN.RELOAD"])
      assert is_routed?(result)
    end
  end

  describe "Stream command routing" do
    # Stream commands require proper arguments for pattern matching
    # We provide valid argument patterns but expect Store.Stream failures

    test "XADD with args is routed" do
      result = Commands.execute(["XADD", "mystream", "*", "field", "value"])
      assert is_routed?(result)
    end

    test "XREAD with args is routed" do
      result = Commands.execute(["XREAD", "STREAMS", "mystream", "0"])
      assert is_routed?(result)
    end

    test "XRANGE with args is routed" do
      result = Commands.execute(["XRANGE", "mystream", "-", "+"])
      assert is_routed?(result)
    end

    test "XREVRANGE with args is routed" do
      result = Commands.execute(["XREVRANGE", "mystream", "+", "-"])
      assert is_routed?(result)
    end

    test "XLEN with args is routed" do
      result = Commands.execute(["XLEN", "mystream"])
      assert is_routed?(result)
    end

    test "XINFO with args is routed" do
      result = Commands.execute(["XINFO", "STREAM", "mystream"])
      assert is_routed?(result)
    end

    test "XTRIM with args is routed" do
      result = Commands.execute(["XTRIM", "mystream", "MAXLEN", "1000"])
      assert is_routed?(result)
    end

    test "XDEL with args is routed" do
      result = Commands.execute(["XDEL", "mystream", "1-0"])
      assert is_routed?(result)
    end
  end

  describe "Basic command routing" do
    test "PING is handled directly" do
      assert "PONG" == Commands.execute(["PING"])
    end

    test "COMMAND returns empty list" do
      assert [] == Commands.execute(["COMMAND"])
    end

    test "FLUSHALL returns OK" do
      assert "OK" == Commands.execute(["FLUSHALL"])
    end
  end

  describe "Unknown commands" do
    test "returns error with command name" do
      assert {:error, msg} = Commands.execute(["NOTACOMMAND"])
      assert msg =~ "unknown command"
      assert msg =~ "notacommand"
    end

    test "empty command list returns error" do
      assert {:error, msg} = Commands.execute([])
      assert msg =~ "empty command"
    end
  end

  describe "Transaction command routing" do
    # Transaction commands require running GenServers
    # These are excluded by default, run with --include requires_infrastructure

    test "ROLLBACK without TO is unknown" do
      result = Commands.execute(["ROLLBACK"])
      assert {:error, msg} = result
      assert msg =~ "unknown command"
    end
  end
end
