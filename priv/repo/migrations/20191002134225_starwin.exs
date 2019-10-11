defmodule NameGuess.Repo.Migrations.Starwin do
  use Ecto.Migration

  def change do
    alter table("high_score") do
      add :is_winner, :boolean, default: false
    end
  end
end
