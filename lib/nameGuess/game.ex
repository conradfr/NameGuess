defmodule NameGuess.Game do
  alias __MODULE__
  alias NameGuess.Picker
  alias NameGuess.People
  alias NameGuess.Space
  alias NameGuess.Score
  alias NameGuess.PictureRotate
  alias Timex

  defstruct [
    :space,
    :state,
    :score,
    :score_rank_this_month,
    :score_rank_all_time,
    :current_pick,
    :current_choices,
    :tick,
    :countdown_timer,
    :countdown_from,
    :wrong_pick,
    :past_picks,
    :started_at,
    :ended_at
  ]

  @max_seconds_per_round 15

  # -------------------------------------------------- NEW --------------------------------------------------

  @spec new(Space) :: Game
  def new(space) do
    {:ok, datetime_start} = DateTime.now("Etc/UTC")

    new_game = %Game{
      space: space,
      state: :ok,
      score: 0,
      score_rank_this_month: 0,
      score_rank_all_time: 0,
      countdown_timer: nil,
      tick: @max_seconds_per_round,
      countdown_from: @max_seconds_per_round,
      current_pick: nil,
      current_choices: nil,
      wrong_pick: nil,
      past_picks: [],
      started_at: datetime_start,
      ended_at: nil
    }

    put_next_round(new_game)
  end

  # -------------------------------------------------- TICK --------------------------------------------------

  def end_of_countdown(%{state: :ok} = game) do
    updated = %{game | tick: 0, countdown_timer: nil}
    # At the end of the countdown we force a guess with no choice
    guess(updated, nil)
  end

  # -------------------------------------------------- GUESS --------------------------------------------------

  @spec guess(Game, integer | nil) :: Game
  def guess(game, pick)

  def guess(%{state: :ok, countdown_timer: timer} = game, pick) do
    if timer != nil, do: Process.cancel_timer(timer)
    game = %{game | countdown_timer: nil}
    {:ok, datetime_end} = DateTime.now("Etc/UTC")

    spawn(fn ->
      PictureRotate.rotate(game.current_pick)
      # Increase global game counter after the first guess
      if game.score == 0, do: Score.add_to_games_counter(game.space)
    end)

    updated_game =
      cond do
        # CORRECT ANSWER
        pick == game.current_pick.id ->
          has_correct_answer(game, datetime_end)

        # WRONG ANSWER
        true ->
          has_lost(game, pick, datetime_end)
      end

    updated_game
  end

  @doc """
    Should not happen
  """
  def guess(game, _pick) do
    game
  end

  @spec has_correct_answer(Game, DateTime) :: Game
  defp has_correct_answer(game, datetime_end) do
    spawn(fn -> People.Stats.has_been_guessed(game.space, game.current_pick.id) end)

    # WINNER ?
    case People.get_keys_total(game.space) == length(game.past_picks) do
      true ->
        has_win(game, datetime_end)

      _ ->
        %{game | score: game.score + 1, state: :ok_next}
    end
  end

  @spec has_win(Game, DateTime) :: Game
  defp has_win(game, datetime_end) do
    game = %{
      game
      | score: game.score + 1,
        state: :win_next,
        ended_at: datetime_end
    }

    {score_rank_this_month, score_rank_all_time} = get_score_ranks(game, datetime_end)

    game = %{
      game
      | score_rank_this_month: score_rank_this_month,
        score_rank_all_time: score_rank_all_time
    }

    Score.add_to_scores(game)
    game
  end

  @spec has_lost(Game, integer, DateTime) :: Game
  defp has_lost(game, pick, datetime_end) do
    {score_rank_this_month, score_rank_all_time} = get_score_ranks(game, datetime_end)

    game = %{
      game
      | state: :gameover_next,
        wrong_pick: pick,
        ended_at: datetime_end,
        score_rank_this_month: score_rank_this_month,
        score_rank_all_time: score_rank_all_time
    }

    spawn(fn ->
      People.Stats.has_not_been_guessed(game.space, game.current_pick.id, pick)
      Score.add_to_scores(game)
    end)

    game
  end

  # -------------------------------------------------- STATE --------------------------------------------------

  def next_state(game) do
    case game.state do
      :ok_next ->
        %{game | state: :ok}
        |> put_next_round()

      :win_next ->
        %{game | state: :win }

      :gameover_next ->
        %{game | state: :gameover }

      _ ->
        game
    end
  end

  defp put_next_round(%{state: :ok, space: space, past_picks: past_picks, score: round} = game) do
    {pick, choices} = Picker.pick_next_round(space, past_picks, round)
    past_picks = past_picks ++ [pick.id]

    %{
      game
      | current_pick: pick,
        current_choices: choices,
        past_picks: past_picks,
        wrong_pick: nil,
        tick: @max_seconds_per_round,
    }
  end

  # -------------------------------------------------- UTILS --------------------------------------------------

  @spec get_max_interval(Game) :: integer
  def get_max_interval(_game) do
    @max_seconds_per_round
  end

  def add_best(%{state: state} = game, name) when state in [:gameover, :win] do
    Score.add_to_best_scores(name, game)
    game
  end

  @spec get_score_ranks(Game, DateTime) :: tuple
  def get_score_ranks(game, datetime_end) do
    duration = get_duration(game, datetime_end)
    score_rank_all_time = Score.get_score_rank(game.space, game.score, duration)
    score_rank_this_month = Score.get_score_rank_this_month(game.space, game.score, duration)
    {score_rank_this_month, score_rank_all_time}
  end

  @spec get_duration(Game, DateTime) :: integer
  def get_duration(game, datetime_end \\ nil)

  def get_duration(game, datetime_end) when datetime_end != nil do
    DateTime.diff(datetime_end, game.started_at)
  end

  def get_duration(%{ended_at: ended_at} = game, _datetime_end) when ended_at == nil do
    {:ok, datetime_end} = DateTime.now("Etc/UTC")
    DateTime.diff(datetime_end, game.started_at)
  end

  def get_duration(game, _datetime_end) do
    DateTime.diff(game.ended_at, game.started_at)
  end
end
