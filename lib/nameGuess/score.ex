defmodule NameGuess.Score do
  import Ecto.Query, only: [from: 2]
  use Ecto.Schema
  alias NameGuess.Repo
  alias NameGuess.Game
  alias NameGuess.Space
  alias NameGuess.GameScore
  alias NameGuess.HighScore
  alias NameGuess.Cache
  require Logger

  @number_of_high_scores 25

  # ---------- Stats ----------

  @spec add_to_games_counter(Space) :: tuple
  def add_to_games_counter(space) do
    {:ok, _result} = Space.increase_games_counter(space)
    Cache.increment_games_counter(space)
  end

  @spec get_number_of_games(Space) :: integer
  def get_number_of_games(space) do
    case Cache.has_game_counter(space) do
      true ->
        Cache.get_game_counter(space)

      false ->
        unless space.played == nil do
          # potentially not the correct value, but eh.
          Cache.set_game_counter(space)
          space.played
        else
          0
        end
    end
  end

  @spec get_space_duration(Space) :: String.t() | nil
  def get_space_duration(space) do
    unless space.duration == nil do
      space.duration
      |> Kernel./(60)
      |> Float.ceil()
      |> Kernel.*(60)
      |> Timex.Duration.from_seconds()
      |> Elixir.Timex.Format.Duration.Formatters.Humanized.format()
    else
      nil
    end
  end

  # ---------- Scores ----------

  @spec add_to_scores(Game) :: tuple
  def add_to_scores(game) do
    Logger.info("(#{game.space.codename}) Add to scores: #{game.score}")

    GameScore.add_to_scores(game.space, game.score)

    duration = Game.get_duration(game)
    Space.increase_duration_counter(game.space, duration)
  end

  @spec count_score(Space, integer) :: integer
  def count_score(space, score) do
    query =
      from(gs in "game_score",
        select: gs.counter,
        where: gs.score == ^score and gs.space_id == ^space.id
      )

    Repo.one(query) || 0
  end

  @spec is_high_score?(Space, integer, integer) :: boolean
  def is_high_score?(space, score, duration)

  def is_high_score?(_space, 0, _duration) do
    false
  end

  def is_high_score?(space, score, duration) do
    {count_this_week, count_all} = high_score_rank_count(space, score, duration)

    count_all < @number_of_high_scores or
      count_this_week < @number_of_high_scores
  end

  @spec get_score_rank(Space, integer, integer) :: integer
  def get_score_rank(space, score, duration) do
    {_count_this_week, count_all} = high_score_rank_count(space, score, duration)
    count_all + 1
  end

  @spec get_score_rank_this_week(Space, integer, integer) :: integer
  def get_score_rank_this_week(space, score, duration) do
    {count_this_week, _count_all} = high_score_rank_count(space, score, duration)
    count_this_week + 1
  end

  @spec high_score_rank_count(Space, integer, integer) :: tuple
  defp high_score_rank_count(space, score, duration) do
    high_score_all_query =
      from(hs in "high_score",
        select: count(hs.id),
        where:
          hs.space_id == ^space.id and
            (hs.score > ^score or (hs.score == ^score and hs.duration < ^duration))
      )

    count_all = Repo.one(high_score_all_query)

    high_score_this_week_query =
      from(q in high_score_all_query,
        where:
          fragment(
            "EXTRACT(WEEK FROM ? at time zone 'UTC' at time zone 'Europe/Paris') = EXTRACT(WEEK FROM now() at time zone 'Europe/Paris')",
            q.scored_at
          )
      )

    count_this_week = Repo.one(high_score_this_week_query)

    {count_this_week, count_all}
  end

  @spec get_highest_score(Space) :: list
  def get_highest_score(space) do
    high_score = get_high_scores(space, 1)

    if length(high_score) > 0 do
      hd(high_score)
    else
      [nil, nil]
    end
  end

  @spec get_highest_score_this_week(Space) :: list
  def get_highest_score_this_week(space) do
    high_score = get_high_scores_this_week(space, 1)

    if length(high_score) > 0 do
      hd(high_score)
    else
      [nil, nil]
    end
  end

  @spec get_high_scores(Space, integer) :: list
  def get_high_scores(space, how_many \\ @number_of_high_scores) do
    query = get_high_scores_query(space.id, how_many)
    Repo.all(query)
  end

  @spec get_high_scores_this_week(Space, integer) :: list
  def get_high_scores_this_week(space, how_many \\ @number_of_high_scores) do
    query =
      from(q in get_high_scores_query(space.id, how_many),
        where:
          fragment(
            "EXTRACT(WEEK FROM ? at time zone 'UTC' at time zone 'Europe/Paris') = EXTRACT(WEEK FROM now() at time zone 'Europe/Paris')",
            q.scored_at
          )
      )

    Repo.all(query)
  end

  @spec get_high_scores_query(integer, integer) :: Repo.query()
  defp get_high_scores_query(space_id, how_many) do
    from(hs in "high_score",
      select: [hs.name, hs.score, hs.is_winner],
      order_by: [desc: hs.score, asc: hs.duration],
      where: hs.space_id == ^space_id,
      limit: ^how_many,
      offset: 0
    )
  end

  @spec add_to_best_scores(String.t(), Game) :: none | tuple
  def add_to_best_scores(name, game)

  def add_to_best_scores(name, %Game{score: score} = _game) when name == "" or score == 0 do
    # nothing
  end

  def add_to_best_scores(name, game) do
    duration = Game.get_duration(game)

    high_score = %HighScore{
      space: game.space,
      name: name,
      score: game.score,
      duration: duration,
      is_winner: game.state == :win,
      scored_at: game.ended_at |> DateTime.truncate(:second)
    }

    Repo.insert(high_score)
  end
end
