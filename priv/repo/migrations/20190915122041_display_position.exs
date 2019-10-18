defmodule NameGuess.Repo.Migrations.DisplayPosition do
  use Ecto.Migration

  def change do
    alter table("space") do
      add :display_position, :boolean, default: true
    end
  end
end
