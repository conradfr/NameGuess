defmodule NameGuess.Repo.Migrations.Reference do
  use Ecto.Migration
  alias NameGuess.Repo

  def change do
    alter table("person") do
      add :reference, :string, default: nil
    end

    flush()

    Repo.query(
      """
      UPDATE person SET reference = person.id::text WHERE person.id is not null;
      """,
      []
    )

    flush()

    alter table("person") do
      modify :reference, :string, null: false
    end

    create unique_index("person", [:reference, :source])

    alter table("person") do
      add :img_source, :text, default: nil
    end

    flush()

    Repo.query(
      """
      UPDATE person SET img_source = person.img WHERE person.id is not null;
      """,
      []
    )

    flush()

    alter table("person") do
      modify :img_source, :text, null: false
    end
  end
end
