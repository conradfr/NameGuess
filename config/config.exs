# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :nameGuess,
  ecto_repos: [NameGuess.Repo]

# Configures the endpoint
config :nameGuess, NameGuessWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "lNsoSff3VUkzXrU9s5QrZd6mHtsKtWqBfrBeMP5ROm7S+zumLUMHo/sOEeYX9X3Z",
  render_errors: [view: NameGuessWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: NameGuess.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "A+Bcyn2fQG0/bS92HxCNk1D1Kf9uYmhW"
  ]

config :nameGuess, NameGuess.Scheduler,
  jobs: [
    update: [
      schedule: "04 03 * * *",
      task: {NameGuess.Update, :people, []}
    ],
    pictures: [
      schedule: "0 3 * * 1",
      task: {NameGuess.Update, :pictures, []}
    ],
    homepage_image: [
      schedule: "*/5 * * * *",
      task: {NameGuess.Image, :homepage, []}
    ]
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  colors: [enabled: true]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

if (Mix.env() == :dev) do
  import_config "config_app.exs"
end
