defmodule NameGuessWeb.Plugs.Cookies do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    case Map.get(conn.cookies, "name", nil) do
      nil -> conn
      value -> put_session(conn, "name", value)
    end
  end
end
