defmodule NameGuess.Repo.Migrations.HideNoOverloading do
  use Ecto.Migration

  def change do
    alter table("space") do
      add :hide_no_overloading, :boolean, default: false
    end
  end
end
