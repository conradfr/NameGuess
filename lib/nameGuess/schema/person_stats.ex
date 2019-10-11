defmodule NameGuess.PersonStats do
  use Ecto.Schema
  alias NameGuess.Person
  alias NameGuess.Space
  alias NameGuess.Repo

  @primary_key false

  schema "person_stats" do
    field(:guessed, :integer, default: 0)
    field(:not_guessed, :integer, default: 0)
    belongs_to(:person, Person, primary_key: true)
    belongs_to(:space, Space, primary_key: true)
  end

  @spec add_guessed(integer, integer) :: any
  def add_guessed(space_id, person_id) do
    Repo.query(
      """
      INSERT INTO person_stats (person_id, space_id, guessed)
      VALUES ($1, $2, 1)
      ON CONFLICT (person_id, space_id)
      DO
        UPDATE
        SET guessed = person_stats.guessed + 1;
      """,
      [person_id, space_id]
    )
  end

  @spec add_not_guessed(integer, integer) :: any
  def add_not_guessed(space_id, person_id) do
    Repo.query(
      """
      INSERT INTO person_stats (person_id, space_id, not_guessed)
      VALUES ($1, $2, 1)
      ON CONFLICT (person_id, space_id)
      DO
        UPDATE
        SET not_guessed = person_stats.not_guessed + 1;
      """,
      [person_id, space_id]
    )
  end
end
