defmodule Spiredb.ReplicaRole do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:FOLLOWER, 0)
  field(:LEADER, 1)
end

defmodule Spiredb.RegisterStoreRequest.LabelsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule Spiredb.RegisterStoreRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:address, 1, type: :string)
  field(:capacity, 2, type: :uint64)
  field(:labels, 3, repeated: true, type: Spiredb.RegisterStoreRequest.LabelsEntry, map: true)
end

defmodule Spiredb.RegisterStoreResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:store_id, 1, type: :uint64, json_name: "storeId")
end

defmodule Spiredb.HeartbeatRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:store_id, 1, type: :uint64, json_name: "storeId")
  field(:stats, 2, type: Spiredb.StoreStats)
end

defmodule Spiredb.StoreStats do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:available_space, 1, type: :uint64, json_name: "availableSpace")
  field(:region_count, 2, type: :uint32, json_name: "regionCount")
  field(:regions, 3, repeated: true, type: Spiredb.RegionStats)
end

defmodule Spiredb.RegionStats do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
  field(:approximate_size, 2, type: :uint64, json_name: "approximateSize")
  field(:approximate_keys, 3, type: :uint64, json_name: "approximateKeys")
  field(:qps, 4, type: :uint64)
end

defmodule Spiredb.HeartbeatResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule Spiredb.GetRegionRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
end

defmodule Spiredb.GetRegionResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region, 1, type: Spiredb.Region)
end

defmodule Spiredb.GetRegionByKeyRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
end

defmodule Spiredb.GetRegionByKeyResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region, 1, type: Spiredb.Region)
end

defmodule Spiredb.Region do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:start_key, 2, type: :bytes, json_name: "startKey")
  field(:end_key, 3, type: :bytes, json_name: "endKey")
  field(:replicas, 4, repeated: true, type: Spiredb.Replica)
  field(:epoch, 5, type: :uint64)
  field(:leader_store_id, 6, type: :uint64, json_name: "leaderStoreId")
end

defmodule Spiredb.Replica do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:store_id, 1, type: :uint64, json_name: "storeId")
  field(:role, 2, type: Spiredb.ReplicaRole, enum: true)
end

defmodule Spiredb.CreateTableRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:name, 1, type: :string)
  field(:schema_json, 2, type: :bytes, json_name: "schemaJson")
end

defmodule Spiredb.CreateTableResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:table_id, 1, type: :uint64, json_name: "tableId")
end

defmodule Spiredb.GetTableRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof(:identifier, 0)

  field(:id, 1, type: :uint64, oneof: 0)
  field(:name, 2, type: :string, oneof: 0)
end

defmodule Spiredb.GetTableResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:name, 2, type: :string)
  field(:schema_json, 3, type: :bytes, json_name: "schemaJson")
end

defmodule Spiredb.ListTablesRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule Spiredb.ListTablesResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:tables, 1, repeated: true, type: Spiredb.GetTableResponse)
end

defmodule Spiredb.GetClusterInfoRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule Spiredb.GetClusterInfoResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:stores, 1, repeated: true, type: Spiredb.StoreInfo)
end

defmodule Spiredb.StoreInfo do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:address, 2, type: :string)
  field(:state, 3, type: :string)
end

defmodule Spiredb.GetRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
end

defmodule Spiredb.GetResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:value, 1, type: :bytes)
  field(:found, 2, type: :bool)
end

defmodule Spiredb.PutRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
  field(:value, 2, type: :bytes)
end

defmodule Spiredb.PutResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule Spiredb.DeleteRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
end

defmodule Spiredb.DeleteResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:deleted, 1, type: :bool)
end

defmodule Spiredb.BatchPutRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:pairs, 1, repeated: true, type: Spiredb.KVPair)
end

defmodule Spiredb.BatchPutResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3
end

defmodule Spiredb.KVPair do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:key, 1, type: :bytes)
  field(:value, 2, type: :bytes)
end

defmodule Spiredb.GetRegionInfoRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
end

defmodule Spiredb.GetRegionInfoResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region, 1, type: Spiredb.Region)
  field(:stats, 2, type: Spiredb.RegionStats)
end

defmodule Spiredb.SplitRegionRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
  field(:split_key, 2, type: :bytes, json_name: "splitKey")
end

defmodule Spiredb.SplitRegionResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:new_region_id, 1, type: :uint64, json_name: "newRegionId")
  field(:new_peer_ids, 2, repeated: true, type: :uint64, json_name: "newPeerIds")
end

defmodule Spiredb.CoprocessorRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint64, json_name: "regionId")
  field(:plan, 2, type: :bytes)
  field(:ranges, 3, repeated: true, type: Spiredb.KeyRange)
end

defmodule Spiredb.KeyRange do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:start, 1, type: :bytes)
  field(:end, 2, type: :bytes)
end

defmodule Spiredb.CoprocessorResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:data, 1, type: :bytes)
  field(:error, 2, type: :string)
end

defmodule Spiredb.PlacementDriver.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.PlacementDriver", protoc_gen_elixir_version: "0.15.0"

  rpc(:RegisterStore, Spiredb.RegisterStoreRequest, Spiredb.RegisterStoreResponse)

  rpc(:StoreHeartbeat, Spiredb.HeartbeatRequest, Spiredb.HeartbeatResponse)

  rpc(:GetRegion, Spiredb.GetRegionRequest, Spiredb.GetRegionResponse)

  rpc(:GetRegionByKey, Spiredb.GetRegionByKeyRequest, Spiredb.GetRegionByKeyResponse)

  rpc(:CreateTable, Spiredb.CreateTableRequest, Spiredb.CreateTableResponse)

  rpc(:GetTable, Spiredb.GetTableRequest, Spiredb.GetTableResponse)

  rpc(:ListTables, Spiredb.ListTablesRequest, Spiredb.ListTablesResponse)

  rpc(:GetClusterInfo, Spiredb.GetClusterInfoRequest, Spiredb.GetClusterInfoResponse)
end

defmodule Spiredb.PlacementDriver.Stub do
  @moduledoc false

  use GRPC.Stub, service: Spiredb.PlacementDriver.Service
end

defmodule Spiredb.Store.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.Store", protoc_gen_elixir_version: "0.15.0"

  rpc(:Get, Spiredb.GetRequest, Spiredb.GetResponse)

  rpc(:Put, Spiredb.PutRequest, Spiredb.PutResponse)

  rpc(:Delete, Spiredb.DeleteRequest, Spiredb.DeleteResponse)

  rpc(:BatchPut, Spiredb.BatchPutRequest, Spiredb.BatchPutResponse)

  rpc(:GetRegionInfo, Spiredb.GetRegionInfoRequest, Spiredb.GetRegionInfoResponse)

  rpc(:SplitRegion, Spiredb.SplitRegionRequest, Spiredb.SplitRegionResponse)
end

defmodule Spiredb.Store.Stub do
  @moduledoc false

  use GRPC.Stub, service: Spiredb.Store.Service
end

defmodule Spiredb.Coprocessor.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.Coprocessor", protoc_gen_elixir_version: "0.15.0"

  rpc(:Execute, Spiredb.CoprocessorRequest, stream(Spiredb.CoprocessorResponse))
end

defmodule Spiredb.Coprocessor.Stub do
  @moduledoc false

  use GRPC.Stub, service: Spiredb.Coprocessor.Service
end
