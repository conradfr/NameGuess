defmodule NameGuess.GameScore do
  use Ecto.Schema
  alias NameGuess.Repo
  alias NameGuess.Space

  @primary_key {:score, :integer, autogenerate: false}

  schema "game_score" do
    field(:counter, :integer)
    belongs_to(:space, Space)
  end

  @spec add_to_scores(Space, integer) :: any
  def add_to_scores(space, score) do
    Repo.query(
      """
      INSERT INTO game_score (space_id, score, counter)
      VALUES ($1, $2, 1)
      ON CONFLICT (space_id, score)
      DO
        UPDATE
        SET counter = game_score.counter + 1;
      """,
      [space.id, score]
    )
  end
end
