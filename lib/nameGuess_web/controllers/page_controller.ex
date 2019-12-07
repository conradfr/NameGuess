defmodule NameGuessWeb.PageController do
  use NameGuessWeb, :controller
  require Logger
  alias Phoenix.LiveView
  alias NameGuess.Score
  alias NameGuess.People

  def index(conn, _params) do
    space = conn.assigns.space
    number_of_games = Score.get_number_of_games(space)
    high_score_all = Score.get_highest_score(space)
    high_score_this_month = Score.get_highest_score_this_month(space)
    duration = Score.get_space_duration(space)
    number_of_people = People.get_keys_total(space)

    render(conn, "index.html",
      number_of_games: number_of_games,
      high_score: high_score_all,
      high_score_this_month: high_score_this_month,
      duration: duration,
      number_of_people: number_of_people
    )
  end

  def game(conn, _params) do
    ip = conn.remote_ip |> :inet_parse.ntoa() |> to_string()
    Logger.info("game page : #{ip}")

    space = conn.assigns.space
    number_of_people = People.get_keys_total(space)

    LiveView.Controller.live_render(conn, NameGuessWeb.GameView,
      session: %{space: space, number_of_people: number_of_people, cookies: conn.cookies}
    )
  end

  def high_scores(conn, _params) do
    space = conn.assigns.space
    high_scores = Score.get_high_scores(space)
    high_scores_this_month = Score.get_high_scores_this_month(space)

    render(conn, "highscores.html",
      high_scores: high_scores,
      high_scores_this_month: high_scores_this_month
    )
  end
end
