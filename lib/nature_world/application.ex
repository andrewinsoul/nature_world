defmodule NatureWorld.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NatureWorldWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:nature_world, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: NatureWorld.PubSub},
      {Registry, keys: :unique, name: NatureWorld.Registry},
      NatureWorld.CitizenSupervisor,
      NatureWorld.Simulation,
      # Start a worker by calling: NatureWorld.Worker.start_link(arg)
      # {NatureWorld.Worker, arg},
      # Start to serve requests, typically the last entry
      NatureWorldWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NatureWorld.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NatureWorldWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
