defmodule RpgIdle.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RpgIdleWeb.Telemetry,
      RpgIdle.Repo,
      {DNSCluster, query: Application.get_env(:rpg_idle, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RpgIdle.PubSub},
      {Registry, keys: :unique, name: RpgIdle.GameRegistry},
      RpgIdleWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RpgIdle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RpgIdleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
