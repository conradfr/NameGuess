defmodule NameGuessWeb.Router do
  use NameGuessWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NameGuessWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NameGuessWeb.Plugs.Space
  end

  pipeline :game do
    plug NameGuessWeb.Plugs.Cookies
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NameGuessWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/highscores", PageController, :high_scores

    get "/:space", PageController, :index
    get "/:space/highscores", PageController, :high_scores

    live "/stats", StatsLive
    live "/stats/:division_key", StatsLive

    live "/:space/stats", StatsLive, as: :stats_spaced
    live "/:space/stats/:division_key", StatsLive
  end

  scope "/", NameGuessWeb do
    pipe_through [:browser, :game]

    live "/game", GameLive
    live "/:space/game", GameLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", NameGuessWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: NameGuessWeb.Telemetry
    end
  end
end
