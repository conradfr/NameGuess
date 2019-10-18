defmodule NameGuess.GameStats do
  import Ecto.Changeset
  use Ecto.Schema
  alias NameGuess.Repo

  @primary_key {:id, :integer, autogenerate: false}

  schema "game_stats" do
    field(:played, :integer, default: 0)
    field(:duration, :integer, default: 0)
    field(:last_picked_state, {:array, :integer})
  end

  @doc false
  def update_picker_state(game_stats, attrs \\ %{}) do
    game_stats
    |> cast(attrs, [:last_picked_state])
    |> validate_required([:last_picked_state])
  end

  def increase_games_counter() do
    Repo.query(
      """
      INSERT INTO game_stats (id, played)
      VALUES (0, 1)
      ON CONFLICT (id)
      DO
        UPDATE
        SET played = game_stats.played + 1;
      """,
      []
    )
  end

  #  def increase_duration_counter(duration) do
  #    Repo.query(
  #      """
  #      INSERT INTO game_stats (id, duration)
  #      VALUES (0, $1)
  #      ON CONFLICT (id)
  #      DO
  #        UPDATE
  #        SET duration = game_stats.duration + $1;
  #      """,
  #      [duration]
  #    )
  #  end
end
