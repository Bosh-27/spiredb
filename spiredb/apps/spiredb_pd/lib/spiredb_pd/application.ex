defmodule SpiredbPd.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # PD.Server is a Ra machine, managed by Ra cluster
    # It's started via Ra APIs, not supervised here

    # In releases, always start production services
    # Use config :spiredb_pd, :disable_services, true to disable in tests

    # Explicitly start Ra default system if not already running
    # This is required for :ra 2.x to function correctly
    case :ra_system.start_default() do
      {:ok, _} ->
        :ok

      {:error, {:already_started, _}} ->
        :ok

      {:error, reason} ->
        # Log error but don't crash yet, let supervisors handle it
        IO.warn("Failed to start Ra default system: #{inspect(reason)}")
    end

    children =
      if Application.get_env(:spiredb_pd, :disable_services, false) do
        # Services disabled (for testing)
        []
      else
        # Start gRPC API server and Scheduler
        [
          PD.Supervisor,
          PD.API.GRPCServerSupervisor,
          PD.Scheduler
        ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpiredbPd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
