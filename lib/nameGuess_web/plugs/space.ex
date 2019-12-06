defmodule NameGuessWeb.Plugs.Space do
  import Plug.Conn
  alias NameGuess.Repo
  alias NameGuess.Space

  def init(options), do: options

  def call(conn, _opts) do
    default_space_codename = Application.get_env(:nameGuess, :default_space_codename)

    space =
      conn.params
      |> Map.get("space", default_space_codename)
      |> (&Repo.get_by(Space, codename: &1)).()

    unless space == nil do
      assign(conn, :space, space)
      |> put_session(:space, space)
    else
      conn
      |> Phoenix.Controller.render(NameGuessWeb.ErrorView, :"404")
      |> halt()
    end
  end
end
