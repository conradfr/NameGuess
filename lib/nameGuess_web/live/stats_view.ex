defmodule NameGuessWeb.StatsView do
  use Phoenix.LiveView
  alias NameGuessWeb.Router.Helpers, as: Routes
  alias NameGuess.Score
  alias NameGuess.People
  alias NameGuess.Space
  alias NameGuess.People.Stats

  def render(assigns) do
    NameGuessWeb.PageView.render("stats.html", assigns)
  end

  def mount(_params, session, socket) do
    space = session["space"]

    number_of_people = People.get_keys_total(space)
    most_guessed = Stats.get_most_guessed(space)
    least_guessed = Stats.get_least_guessed(space)
    number_of_games = Score.get_number_of_games(space)
    duration = Score.get_space_duration(space)
    number_of_score_0 = Score.count_score(space, 0)

    divisions = People.get_divisions(space)

    divisions =
      unless length(divisions) == 1 do
        [{"All", ""} | People.get_divisions(space)]
      else
        divisions
      end

    socket =
      assign(socket,
        space: space,
        most_guessed: most_guessed,
        least_guessed: least_guessed,
        number_of_games: number_of_games,
        duration: duration,
        number_of_people: number_of_people,
        number_of_score_0: number_of_score_0,
        divisions: divisions,
        division_selected: nil
      )

    {:ok, socket}
  end

  # todo check why called two times

  def handle_params(%{"division_key" => division_key}, _uri, socket) do
    division_name = get_division_full(socket.assigns.space, division_key)
    most_guessed = Stats.get_most_guessed(socket.assigns.space, division_name)
    least_guessed = Stats.get_least_guessed(socket.assigns.space, division_name)

    socket =
      assign(socket,
        most_guessed: most_guessed,
        least_guessed: least_guessed,
        division_selected: division_key
      )

    {:noreply, socket}
  end

  def handle_params(_, _uri, socket) do
    most_guessed = Stats.get_most_guessed(socket.assigns.space)
    least_guessed = Stats.get_least_guessed(socket.assigns.space)

    socket =
      assign(socket,
        most_guessed: most_guessed,
        least_guessed: least_guessed,
        division_selected: ""
      )

    {:noreply, socket}
  end

  def handle_event("division_change", %{"divisions" => division_choice} = _division, socket) do
    division_key = Map.get(division_choice, "division_id")

    {:noreply,
     live_redirect(
       socket,
       to:
         Routes.live_path(
           socket,
           NameGuessWeb.StatsView,
           socket.assigns.space.codename,
           division_key
         )
     )}
  end

  @spec get_division_full(Space, String.t()) :: String.t()
  defp get_division_full(space, division_key) do
    divisions = People.get_divisions(space)
    {name, _key} = Enum.find(divisions, fn {_name, key} -> key == division_key end)
    name
  end
end
