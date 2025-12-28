defmodule Store.Supervisor do
  @moduledoc """
  Supervisor for Store components.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    db_path = Application.get_env(:spiredb_store, :rocksdb_path, "/var/lib/spiredb/data")

    children = [
      # KV Engine (must start before Server)
      {Store.KV.Engine, [path: db_path, name: Store.KV.Engine]},

      # Main store server (manages regions + KV engine)
      {Store.Server, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
