defmodule NameGuess.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      NameGuess.Repo,
      NameGuess.Cache,
      {Task.Supervisor, name: NameGuess.TaskSupervisor},
      # Starts a worker by calling: NameGuess.Worker.start_link(arg)
      # {NameGuess.Worker, arg},
      NameGuess.Scheduler,
      NameGuess.PickerSupervisor,
      #      NameGuess.Picker,
      NameGuess.PictureRotate,
      Supervisor.child_spec({Task, &NameGuess.Update.startup/0},
        id: StartupTask,
        restart: :temporary
      ),
      # Start the endpoint when the application starts
      NameGuessWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NameGuess.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NameGuessWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
