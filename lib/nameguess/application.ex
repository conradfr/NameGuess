defmodule NameGuess.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      NameGuess.Repo,
      NameGuess.Cache,
      {Task.Supervisor, name: NameGuess.TaskSupervisor},
      # Start the Telemetry supervisor
      NameGuessWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: NameGuess.PubSub},
      NameGuess.Scheduler,
      NameGuess.PickerSupervisor,
      #      NameGuess.Picker,
      NameGuess.PictureRotate,
      Supervisor.child_spec({Task, &NameGuess.Update.startup/0},
        id: StartupTask,
        restart: :temporary
      ),
      # Start the Endpoint (http/https)
      NameGuessWeb.Endpoint
      # Start a worker by calling: NameGuess.Worker.start_link(arg)
      # {NameGuess.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NameGuess.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NameGuessWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
