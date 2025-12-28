defmodule Spiredb.Data.ScanRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint32, json_name: "regionId")
  field(:start_key, 2, type: :bytes, json_name: "startKey")
  field(:end_key, 3, type: :bytes, json_name: "endKey")
  field(:batch_size, 4, type: :uint32, json_name: "batchSize")
  field(:limit, 5, type: :uint32)
  field(:read_follower, 6, type: :bool, json_name: "readFollower")
end

defmodule Spiredb.Data.ScanResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:arrow_batch, 1, type: :bytes, json_name: "arrowBatch")
  field(:has_more, 2, type: :bool, json_name: "hasMore")
  field(:stats, 3, type: Spiredb.Data.ScanStats)
end

defmodule Spiredb.Data.ScanStats do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:rows_returned, 1, type: :uint64, json_name: "rowsReturned")
  field(:bytes_read, 2, type: :uint64, json_name: "bytesRead")
  field(:scan_time_ms, 3, type: :uint32, json_name: "scanTimeMs")
end

defmodule Spiredb.Data.GetRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint32, json_name: "regionId")
  field(:key, 2, type: :bytes)
  field(:read_follower, 3, type: :bool, json_name: "readFollower")
end

defmodule Spiredb.Data.GetResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:value, 1, type: :bytes)
  field(:found, 2, type: :bool)
end

defmodule Spiredb.Data.BatchGetRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:region_id, 1, type: :uint32, json_name: "regionId")
  field(:keys, 2, repeated: true, type: :bytes)
end

defmodule Spiredb.Data.BatchGetResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:arrow_batch, 1, type: :bytes, json_name: "arrowBatch")
end

defmodule Spiredb.Data.DataAccess.Service do
  @moduledoc false

  use GRPC.Service, name: "spiredb.data.DataAccess", protoc_gen_elixir_version: "0.15.0"

  rpc(:Scan, Spiredb.Data.ScanRequest, stream(Spiredb.Data.ScanResponse))

  rpc(:Get, Spiredb.Data.GetRequest, Spiredb.Data.GetResponse)

  rpc(:BatchGet, Spiredb.Data.BatchGetRequest, Spiredb.Data.BatchGetResponse)
end

defmodule Spiredb.Data.DataAccess.Stub do
  @moduledoc false

  use GRPC.Stub, service: Spiredb.Data.DataAccess.Service
end
