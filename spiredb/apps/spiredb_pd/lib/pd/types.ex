defmodule PD.Types do
  @moduledoc """
  Data structures for Placement Driver (PD).

  Defines the core types for cluster metadata management.
  """

  defmodule Region do
    @moduledoc """
    Represents a region (shard) of the key space.

    A region is a contiguous range of keys that is replicated across multiple stores.
    """

    @type t :: %__MODULE__{
            id: non_neg_integer(),
            # Inclusive
            start_key: binary(),
            # Exclusive
            end_key: binary(),
            # Nodes hosting this region
            stores: [atom()],
            # Version, increments on changes
            epoch: non_neg_integer(),
            # Current Raft leader
            leader: atom() | nil
          }

    defstruct [
      :id,
      :start_key,
      :end_key,
      stores: [],
      epoch: 1,
      leader: nil
    ]
  end

  defmodule Store do
    @moduledoc """
    Represents a store node in the cluster.

    Tracks the health and status of each node.
    """

    @type t :: %__MODULE__{
            node: atom(),
            # Region IDs hosted by this store
            regions: [non_neg_integer()],
            last_heartbeat: DateTime.t(),
            state: :up | :down
          }

    defstruct [
      :node,
      regions: [],
      last_heartbeat: nil,
      state: :up
    ]
  end
end
