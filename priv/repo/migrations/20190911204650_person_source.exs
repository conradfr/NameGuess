defmodule NameGuess.Repo.Migrations.PersonSource do
  use Ecto.Migration
  alias NameGuess.Repo

  def change do
    alter table("person") do
      add :source, :string
    end

    flush()

    Repo.query(
      """
        UPDATE person
        SET source = $1;
      """,
      ["bamboohr"]
    )

    flush()

    alter table("person") do
      modify :source, :string, null: false
    end

    flush()
  end
end
