defmodule SpiredbCommonTest do
  use ExUnit.Case
  doctest SpiredbCommon

  test "greets the world" do
    assert SpiredbCommon.hello() == :world
  end
end
