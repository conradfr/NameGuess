defmodule NameGuessWeb.Router do
  use NameGuessWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NameGuessWeb.Plugs.Space
    plug :put_live_layout, {NameGuessWeb.LayoutView, "app.html"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NameGuessWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/game", PageController, :game
    get "/highscores", PageController, :high_scores

    live "/stats", StatsView
    live "/stats/:division_key", StatsView

    get "/:space", PageController, :index
    get "/:space/game", PageController, :game
    get "/:space/highscores", PageController, :high_scores

    live "/:space/stats", StatsView, as: :stats_spaced
    live "/:space/stats/:division_key", StatsView
  end

  # Other scopes may use custom stacks.
  # scope "/api", NameGuessWeb do
  #   pipe_through :api
  # end
end
