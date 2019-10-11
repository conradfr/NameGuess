defmodule NameGuessWeb.Router do
  use NameGuessWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NameGuessWeb.Plugs.Space
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NameGuessWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/game", PageController, :game
    get "/highscores", PageController, :high_scores

    live "/stats", StatsView, session: [:space]
    live "/stats/:division_key", StatsView, session: [:space]

    get "/:space", PageController, :index
    get "/:space/game", PageController, :game
    get "/:space/highscores", PageController, :high_scores

    live "/:space/stats", StatsView, session: [:space], as: :stats_spaced
    live "/:space/stats/:division_key", StatsView, session: [:space]
  end

  # Other scopes may use custom stacks.
  # scope "/api", NameGuessWeb do
  #   pipe_through :api
  # end
end
