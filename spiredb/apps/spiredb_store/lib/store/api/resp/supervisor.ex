defmodule Store.API.RESP.Supervisor do
  @moduledoc """
  Supervisor for RESP TCP server using Ranch.

  Manages the Ranch listener with configurable connection limits and timeouts.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port) || Application.get_env(:spiredb_store, :resp_port, 6379)
    max_connections = Application.get_env(:spiredb_store, :resp_max_connections, 10_000)

    Logger.info("Starting RESP server on port #{port} (max connections: #{max_connections})")

    # Ranch listener configuration
    ranch_opts = %{
      socket_opts: [port: port],
      max_connections: max_connections,
      # Number of acceptor processes
      num_acceptors: 100
    }

    case :ranch.start_listener(
           :resp_tcp,
           :ranch_tcp,
           ranch_opts,
           Store.API.RESP.Handler,
           []
         ) do
      {:ok, _pid} ->
        Logger.info("RESP server started successfully")
        # Return empty supervisor (Ranch manages its own supervision)
        Supervisor.init([], strategy: :one_for_one)

      {:error, {:already_started, _pid}} ->
        Logger.info("RESP server already running")
        Supervisor.init([], strategy: :one_for_one)

      {:error, reason} ->
        Logger.error("Failed to start RESP listener: #{inspect(reason)}")
        {:stop, reason}
    end
  end
end
