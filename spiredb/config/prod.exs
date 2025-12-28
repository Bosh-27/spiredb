import Config

# Production environment configuration
config :spiredb_store,
  resp_port: String.to_integer(System.get_env("SPIRE_RESP_PORT") || "6379"),
  resp_max_connections:
    String.to_integer(System.get_env("SPIRE_RESP_MAX_CONNECTIONS") || "10000"),
  resp_connection_timeout:
    String.to_integer(System.get_env("SPIRE_RESP_CONNECTION_TIMEOUT") || "60000"),
  rocksdb_path: System.get_env("SPIRE_ROCKSDB_PATH") || "/var/lib/spiredb/data",
  raft_data_dir: System.get_env("SPIRE_RAFT_DATA_DIR") || "/var/lib/spiredb/raft"

# Configure logger level
config :logger, level: :info

# For OTP 27+: Configure the default handler to use JSON formatting
# This replaces the need for backends configuration
# LoggerJSON disabled due to crashes with Erlang logs
# config :logger, :default_handler,
#   formatter:
#     {LoggerJSON.Formatters.GoogleCloud,
#      metadata: [:request_id, :region_id, :command, :store_id, :node]}

# OpenTelemetry configuration
# Set traces_exporter to :none to disable, or configure an OTLP endpoint
config :opentelemetry,
  traces_exporter: :none

# Alternatively, to enable OTLP exporter:
# config :opentelemetry,
#   traces_exporter: {:otlp, endpoint: System.get_env("OTLP_ENDPOINT") || "http://localhost:4318"}
