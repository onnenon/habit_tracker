defmodule HabitQuest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HabitQuestWeb.Telemetry,
      HabitQuest.Repo,
      {DNSCluster, query: Application.get_env(:habit_quest, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HabitQuest.PubSub},
      # Start a worker by calling: HabitQuest.Worker.start_link(arg)
      # {HabitQuest.Worker, arg},
      # Start to serve requests, typically the last entry
      {Finch, name: HabitQuestFinch},
      HabitQuestWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HabitQuest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HabitQuestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
