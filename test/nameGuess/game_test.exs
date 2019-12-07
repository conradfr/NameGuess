defmodule NameGuessWeb.GameTest do
  use ExUnit.Case, async: true
  alias NameGuess.Game

  setup_all do
    game = %Game{
      state: :ok,
      score: 0,
      score_rank_this_month: 0,
      score_rank_all_time: 0,
      tick: 10,
      current_pick: nil,
      current_choices: nil,
      wrong_pick: nil,
      past_picks: [],
      started_at: nil,
      ended_at: nil
    }

    {:ok, game: game}
  end

  # -------------------------------------------------- TICK --------------------------------------------------

  test "test tick", state do
    game = Game.tick(state[:game])

    assert game.tick == 9
  end

  # -------------------------------------------------- STATE --------------------------------------------------

  test "next state when win", state do
    game = %{
      state[:game]
      | state: :win_next
    }

    updated = Game.next_state(game)
    assert updated.state == :win
  end

  test "next state when gameover", state do
    game = %{
      state[:game]
      | state: :gameover_next
    }

    updated = Game.next_state(game)
    assert updated.state == :gameover
  end

  # -------------------------------------------------- DURATION --------------------------------------------------

  test "get game duration", state do
    {:ok, datetime_start} = DateTime.now("Etc/UTC")
    datetime_end = DateTime.add(datetime_start, 5, :second)

    game = %{
      state[:game]
      | started_at: datetime_start,
        ended_at: datetime_end
    }

    result = Game.get_duration(game)

    assert result == 5
  end

  test "get game duration with supplied end", state do
    {:ok, datetime_start} = DateTime.now("Etc/UTC")
    datetime_end = DateTime.add(datetime_start, 7, :second)

    game = %{
      state[:game]
      | started_at: datetime_start
    }

    result = Game.get_duration(game, datetime_end)

    assert result == 7
  end

  test "get game duration w/ no ending", state do
    {:ok, datetime_start} = DateTime.now("Etc/UTC")
    datetime_start_past = DateTime.add(datetime_start, -20, :second)

    game = %{
      state[:game]
      | started_at: datetime_start_past
    }

    result = Game.get_duration(game)

    assert result == 20
  end
end
