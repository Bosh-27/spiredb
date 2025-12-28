defmodule Spiredb.Pd.RegionState do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:REGION_STATE_UNSPECIFIED, 0)
  field(:REGION_STATE_ACTIVE, 1)
  field(:REGION_STATE_SPLITTING, 2)
  field(:REGION_STATE_MERGING, 3)
end

defmodule Spiredb.Pd.GetTableRegionsRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:table_name, 1, type: :string, json_name: "tableName")
end

defmodule Spiredb.Pd.GetTableRegionsResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:regions, 1, repeated: true, type: Spiredb.Pd.Region)
end

defmodule Spiredb.Pd.GetRegionRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
end

defmodule Spiredb.Pd.Region do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint32, json_name: "regionId")
  field(:start_key, 2, type: :bytes, json_name: "startKey")
  field(:end_key, 3, type: :bytes, json_name: "endKey")
  field(:leader_node, 4, type: :string, json_name: "leaderNode")
  field(:followers, 5, repeated: true, type: :string)
  field(:state, 6, type: Spiredb.Pd.RegionState, enum: true)
end

defmodule Spiredb.Pd.RegisterStoreRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:node_name, 1, type: :string, json_name: "nodeName")
end

defmodule Spiredb.Pd.RegisterStoreResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:success, 1, type: :bool)
end

defmodule Spiredb.Pd.HeartbeatRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:node_name, 1, type: :string, json_name: "nodeName")
end

defmodule Spiredb.Pd.HeartbeatResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:success, 1, type: :bool)
end

defmodule Spiredb.Pd.PlacementDriver.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.pd.PlacementDriver", protoc_gen_elixir_version: "0.15.0"

  rpc(:GetTableRegions, Spiredb.Pd.GetTableRegionsRequest, Spiredb.Pd.GetTableRegionsResponse)

  rpc(:GetRegion, Spiredb.Pd.GetRegionRequest, Spiredb.Pd.Region)

  rpc(:RegisterStore, Spiredb.Pd.RegisterStoreRequest, Spiredb.Pd.RegisterStoreResponse)

  rpc(:Heartbeat, Spiredb.Pd.HeartbeatRequest, Spiredb.Pd.HeartbeatResponse)
end

defmodule Spiredb.Pd.PlacementDriver.Stub do
  @moduledoc false

  use GRPC.Stub, service: Spiredb.Pd.PlacementDriver.Service
end
