defmodule NameGuessWeb.LayoutView do
  use NameGuessWeb, :view
  import Ecto.Query, only: [from: 2]
  alias NameGuess.Repo
  alias NameGuess.Space

  def multiple_spaces?(_conn) do
    query =
      from(s in Space,
        where: s.public == true,
        select: count(s.id)
      )

    Repo.one(query) > 1
  end

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
