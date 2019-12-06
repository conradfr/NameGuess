defmodule NameGuessWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :nameGuess

  @session_options [
    store: :cookie,
    key: "_nameGuess_key",
    signing_salt: "AIQ7CFOd"
  ]

  socket "/socket", NameGuessWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]

  # People's pictures
  #
  # Avoid Phoenix digest as images are dynamic and renamed constantly
  plug Plug.Static,
    at: "/pics",
    from: {:nameGuess, "priv/pics"},
    gzip: false,
    cache_control_for_etags: "max-age=3600"

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :nameGuess,
    gzip: true,
    only: ~w(css fonts images js favicon.ico robots.txt),
    cache_control_for_etags: "max-age=86400"

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  plug NameGuessWeb.Router
end
