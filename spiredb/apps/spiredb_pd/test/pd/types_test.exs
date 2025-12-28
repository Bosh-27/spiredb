defmodule PD.TypesTest do
  use ExUnit.Case, async: true

  alias PD.Types.{Region, Store}

  describe "Region struct" do
    test "creates region with all fields" do
      region = %Region{
        id: 1,
        start_key: "a",
        end_key: "z",
        stores: [:node1@localhost, :node2@localhost],
        epoch: 1,
        leader: :node1@localhost
      }

      assert region.id == 1
      assert region.start_key == "a"
      assert region.end_key == "z"
      assert length(region.stores) == 2
      assert region.epoch == 1
      assert region.leader == :node1@localhost
    end

    test "region has default values" do
      region = %Region{
        id: 1,
        start_key: "",
        end_key: ""
      }

      assert region.stores == []
      assert region.epoch == 1
      assert region.leader == nil
    end
  end

  describe "Store struct" do
    test "creates store with all fields" do
      now = DateTime.utc_now()

      store = %Store{
        node: :store1@localhost,
        regions: [1, 2, 3],
        last_heartbeat: now,
        state: :up
      }

      assert store.node == :store1@localhost
      assert store.regions == [1, 2, 3]
      assert store.last_heartbeat == now
      assert store.state == :up
    end

    test "store has default values" do
      store = %Store{
        node: :store1@localhost
      }

      assert store.regions == []
      assert store.last_heartbeat == nil
      assert store.state == :up
    end
  end
end
