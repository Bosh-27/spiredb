defmodule SpireDb.Spiredb.ReplicaRole do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:FOLLOWER, 0)
  field(:LEADER, 1)
end

defmodule SpireDb.Spiredb.RegisterStoreRequest.LabelsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule SpireDb.Spiredb.RegisterStoreRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:address, 1, type: :string)
  field(:capacity, 2, type: :uint64)

  field(:labels, 3,
    repeated: true,
    type: SpireDb.Spiredb.RegisterStoreRequest.LabelsEntry,
    map: true
  )
end

defmodule SpireDb.Spiredb.RegisterStoreResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:store_id, 1, type: :uint64, json_name: "storeId")
end

defmodule SpireDb.Spiredb.HeartbeatRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:store_id, 1, type: :uint64, json_name: "storeId")
  field(:stats, 2, type: SpireDb.Spiredb.StoreStats)
end

defmodule SpireDb.Spiredb.StoreStats do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:available_space, 1, type: :uint64, json_name: "availableSpace")
  field(:region_count, 2, type: :uint32, json_name: "regionCount")
  field(:regions, 3, repeated: true, type: SpireDb.Spiredb.RegionStats)
end

defmodule SpireDb.Spiredb.RegionStats do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
  field(:approximate_size, 2, type: :uint64, json_name: "approximateSize")
  field(:approximate_keys, 3, type: :uint64, json_name: "approximateKeys")
  field(:qps, 4, type: :uint64)
end

defmodule SpireDb.Spiredb.HeartbeatResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule SpireDb.Spiredb.GetRegionRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
end

defmodule SpireDb.Spiredb.GetRegionResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region, 1, type: SpireDb.Spiredb.Region)
end

defmodule SpireDb.Spiredb.GetRegionByKeyRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
end

defmodule SpireDb.Spiredb.GetRegionByKeyResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region, 1, type: SpireDb.Spiredb.Region)
end

defmodule SpireDb.Spiredb.Region do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:start_key, 2, type: :bytes, json_name: "startKey")
  field(:end_key, 3, type: :bytes, json_name: "endKey")
  field(:replicas, 4, repeated: true, type: SpireDb.Spiredb.Replica)
  field(:epoch, 5, type: :uint64)
  field(:leader_store_id, 6, type: :uint64, json_name: "leaderStoreId")
end

defmodule SpireDb.Spiredb.Replica do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:store_id, 1, type: :uint64, json_name: "storeId")
  field(:role, 2, type: SpireDb.Spiredb.ReplicaRole, enum: true)
end

defmodule SpireDb.Spiredb.CreateTableRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:name, 1, type: :string)
  field(:schema_json, 2, type: :bytes, json_name: "schemaJson")
end

defmodule SpireDb.Spiredb.CreateTableResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:table_id, 1, type: :uint64, json_name: "tableId")
end

defmodule SpireDb.Spiredb.GetTableRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof(:identifier, 0)

  field(:id, 1, type: :uint64, oneof: 0)
  field(:name, 2, type: :string, oneof: 0)
end

defmodule SpireDb.Spiredb.GetTableResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:name, 2, type: :string)
  field(:schema_json, 3, type: :bytes, json_name: "schemaJson")
end

defmodule SpireDb.Spiredb.ListTablesRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule SpireDb.Spiredb.ListTablesResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:tables, 1, repeated: true, type: SpireDb.Spiredb.GetTableResponse)
end

defmodule SpireDb.Spiredb.GetClusterInfoRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule SpireDb.Spiredb.GetClusterInfoResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:stores, 1, repeated: true, type: SpireDb.Spiredb.StoreInfo)
end

defmodule SpireDb.Spiredb.StoreInfo do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:address, 2, type: :string)
  field(:state, 3, type: :string)
end

defmodule SpireDb.Spiredb.GetRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
end

defmodule SpireDb.Spiredb.GetResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:value, 1, type: :bytes)
  field(:found, 2, type: :bool)
end

defmodule SpireDb.Spiredb.PutRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
  field(:value, 2, type: :bytes)
end

defmodule SpireDb.Spiredb.PutResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule SpireDb.Spiredb.DeleteRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
end

defmodule SpireDb.Spiredb.DeleteResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:deleted, 1, type: :bool)
end

defmodule SpireDb.Spiredb.BatchPutRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:pairs, 1, repeated: true, type: SpireDb.Spiredb.KVPair)
end

defmodule SpireDb.Spiredb.BatchPutResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule SpireDb.Spiredb.KVPair do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
  field(:value, 2, type: :bytes)
end

defmodule SpireDb.Spiredb.GetRegionInfoRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
end

defmodule SpireDb.Spiredb.GetRegionInfoResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region, 1, type: SpireDb.Spiredb.Region)
  field(:stats, 2, type: SpireDb.Spiredb.RegionStats)
end

defmodule SpireDb.Spiredb.SplitRegionRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
  field(:split_key, 2, type: :bytes, json_name: "splitKey")
end

defmodule SpireDb.Spiredb.SplitRegionResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:new_region_id, 1, type: :uint64, json_name: "newRegionId")
  field(:new_peer_ids, 2, repeated: true, type: :uint64, json_name: "newPeerIds")
end

defmodule SpireDb.Spiredb.CoprocessorRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
  field(:plan, 2, type: :bytes)
  field(:ranges, 3, repeated: true, type: SpireDb.Spiredb.KeyRange)
end

defmodule SpireDb.Spiredb.KeyRange do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:start, 1, type: :bytes)
  field(:end, 2, type: :bytes)
end

defmodule SpireDb.Spiredb.CoprocessorResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:data, 1, type: :bytes)
  field(:error, 2, type: :string)
end

defmodule SpireDb.Spiredb.PlacementDriver.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.PlacementDriver", protoc_gen_elixir_version: "0.15.0"

  rpc(:RegisterStore, SpireDb.Spiredb.RegisterStoreRequest, SpireDb.Spiredb.RegisterStoreResponse)

  rpc(:StoreHeartbeat, SpireDb.Spiredb.HeartbeatRequest, SpireDb.Spiredb.HeartbeatResponse)

  rpc(:GetRegion, SpireDb.Spiredb.GetRegionRequest, SpireDb.Spiredb.GetRegionResponse)

  rpc(
    :GetRegionByKey,
    SpireDb.Spiredb.GetRegionByKeyRequest,
    SpireDb.Spiredb.GetRegionByKeyResponse
  )

  rpc(:CreateTable, SpireDb.Spiredb.CreateTableRequest, SpireDb.Spiredb.CreateTableResponse)

  rpc(:GetTable, SpireDb.Spiredb.GetTableRequest, SpireDb.Spiredb.GetTableResponse)

  rpc(:ListTables, SpireDb.Spiredb.ListTablesRequest, SpireDb.Spiredb.ListTablesResponse)

  rpc(
    :GetClusterInfo,
    SpireDb.Spiredb.GetClusterInfoRequest,
    SpireDb.Spiredb.GetClusterInfoResponse
  )
end

defmodule SpireDb.Spiredb.PlacementDriver.Stub do
  @moduledoc false

  use GRPC.Stub, service: SpireDb.Spiredb.PlacementDriver.Service
end

defmodule SpireDb.Spiredb.Store.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.Store", protoc_gen_elixir_version: "0.15.0"

  rpc(:Get, SpireDb.Spiredb.GetRequest, SpireDb.Spiredb.GetResponse)

  rpc(:Put, SpireDb.Spiredb.PutRequest, SpireDb.Spiredb.PutResponse)

  rpc(:Delete, SpireDb.Spiredb.DeleteRequest, SpireDb.Spiredb.DeleteResponse)

  rpc(:BatchPut, SpireDb.Spiredb.BatchPutRequest, SpireDb.Spiredb.BatchPutResponse)

  rpc(:GetRegionInfo, SpireDb.Spiredb.GetRegionInfoRequest, SpireDb.Spiredb.GetRegionInfoResponse)

  rpc(:SplitRegion, SpireDb.Spiredb.SplitRegionRequest, SpireDb.Spiredb.SplitRegionResponse)
end

defmodule SpireDb.Spiredb.Store.Stub do
  @moduledoc false

  use GRPC.Stub, service: SpireDb.Spiredb.Store.Service
end

defmodule SpireDb.Spiredb.Coprocessor.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.Coprocessor", protoc_gen_elixir_version: "0.15.0"

  rpc(:Execute, SpireDb.Spiredb.CoprocessorRequest, stream(SpireDb.Spiredb.CoprocessorResponse))
end

defmodule SpireDb.Spiredb.Coprocessor.Stub do
  @moduledoc false

  use GRPC.Stub, service: SpireDb.Spiredb.Coprocessor.Service
end
