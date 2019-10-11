defmodule NameGuess.Repo.Migrations.DefaultPersonStats do
  use Ecto.Migration

  def change do
    alter table("person") do
      modify :source, :string, null: false
    end
  end
end
