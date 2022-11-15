defmodule NameGuessWeb.LayoutView do
  use NameGuessWeb, :view
  import Ecto.Query, only: [from: 2]
  alias NameGuess.Repo
  alias NameGuess.Space

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

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
