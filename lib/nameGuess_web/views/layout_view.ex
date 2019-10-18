defmodule NameGuessWeb.LayoutView do
  use NameGuessWeb, :view
  import Ecto.Query, only: [from: 2]
  alias NameGuess.Repo
  alias NameGuess.Space

  def get_space(_conn) do
    query =
      from(s in Space,
        where: s.public == true,
        order_by: s.id,
        select: {s.codename, s.name}
      )

    Repo.all(query)
  end
end
