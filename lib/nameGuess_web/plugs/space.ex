defmodule NameGuessWeb.Plugs.Space do
  import Plug.Conn
  alias NameGuess.Repo
  alias NameGuess.Space

  @default_space_codename "paris"

  def init(options), do: options

  def call(conn, _opts) do
    space =
      conn.params
      |> Map.get("space", @default_space_codename)
      |> (&Repo.get_by(Space, codename: &1)).()

    unless space == nil do
      # todo move to helper ?

      ip = conn.remote_ip |> :inet_parse.ntoa() |> to_string()

      if ip == "::ffff:172.16.202.136" do
        space2 = Repo.get_by(Space, codename: "test")

        assign(conn, :space, space2)
        |> put_session(:space, space2)
      else
        assign(conn, :space, space)
        |> put_session(:space, space)
      end
    else
      conn
      |> Phoenix.Controller.render(NameGuessWeb.ErrorView, :"404")
      |> halt()
    end
  end
end
