defmodule SpireDb.Spiredb.Data.ScanRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint32, json_name: "regionId")
  field(:start_key, 2, type: :bytes, json_name: "startKey")
  field(:end_key, 3, type: :bytes, json_name: "endKey")
  field(:batch_size, 4, type: :uint32, json_name: "batchSize")
  field(:limit, 5, type: :uint32)
  field(:read_follower, 6, type: :bool, json_name: "readFollower")
end

defmodule SpireDb.Spiredb.Data.ScanResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:arrow_batch, 1, type: :bytes, json_name: "arrowBatch")
  field(:has_more, 2, type: :bool, json_name: "hasMore")
  field(:stats, 3, type: SpireDb.Spiredb.Data.ScanStats)
end

defmodule SpireDb.Spiredb.Data.ScanStats do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:rows_returned, 1, type: :uint64, json_name: "rowsReturned")
  field(:bytes_read, 2, type: :uint64, json_name: "bytesRead")
  field(:scan_time_ms, 3, type: :uint32, json_name: "scanTimeMs")
end

defmodule SpireDb.Spiredb.Data.GetRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint32, json_name: "regionId")
  field(:key, 2, type: :bytes)
  field(:read_follower, 3, type: :bool, json_name: "readFollower")
end

defmodule SpireDb.Spiredb.Data.GetResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:value, 1, type: :bytes)
  field(:found, 2, type: :bool)
end

defmodule SpireDb.Spiredb.Data.BatchGetRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint32, json_name: "regionId")
  field(:keys, 2, repeated: true, type: :bytes)
end

defmodule SpireDb.Spiredb.Data.BatchGetResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:arrow_batch, 1, type: :bytes, json_name: "arrowBatch")
end

defmodule SpireDb.Spiredb.Data.DataAccess.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.data.DataAccess", protoc_gen_elixir_version: "0.15.0"

  rpc(:Scan, SpireDb.Spiredb.Data.ScanRequest, stream(SpireDb.Spiredb.Data.ScanResponse))

  rpc(:Get, SpireDb.Spiredb.Data.GetRequest, SpireDb.Spiredb.Data.GetResponse)

  rpc(:BatchGet, SpireDb.Spiredb.Data.BatchGetRequest, SpireDb.Spiredb.Data.BatchGetResponse)
end

defmodule SpireDb.Spiredb.Data.DataAccess.Stub do
  @moduledoc false

  use GRPC.Stub, service: SpireDb.Spiredb.Data.DataAccess.Service
end
