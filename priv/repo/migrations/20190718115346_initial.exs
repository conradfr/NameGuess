defmodule NameGuess.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create_if_not_exists table("space") do
      add :codename, :string, null: false
      add :name, :string, null: false
      add :locations, {:array, :string}, default: []
      add :divisions, {:array, :string}, default: []
      add :public, :boolean, default: false
      add :played, :integer, default: 0
      add :duration, :integer, default: 0
      add :last_picked_state, {:array, :integer}, default: []
      add :timezone, :string, default: "Europe/Paris"
    end

    create table("person") do
      add :division, :string
      add :gender, :string
      add :img, :string
      add :name, :string
      add :position, :string
      add :location, :string

      timestamps()
    end

    create index("person", [:division])
    create index("person", [:location])
    create index("person", [:gender])

    create table("person_stats", primary_key: false) do
      add :person_id, references("person", on_delete: :delete_all), primary_key: true, null: false
      add :space_id, references("space", on_delete: :delete_all), primary_key: true, null: false
      add :guessed, :integer, default: 0
      add :not_guessed, :integer, default: 0
    end

    create table("wrong_name", primary_key: false) do
      add :space_id, references("space", on_delete: :delete_all), primary_key: true, null: false
      add :person_id, references(:person, on_delete: :delete_all), primary_key: true, null: false
      add :name, :string, primary_key: true, null: false
      add :counter, :integer, null: false
    end

    create table("game_score", primary_key: false) do
      add :space_id, references("space", on_delete: :delete_all), primary_key: true, null: false
      add :score, :integer, primary_key: true, null: false
      add :counter, :integer, null: false
    end

    create table("high_score") do
      add :space_id, references("space", on_delete: :delete_all), null: false
      add :score, :integer
      add :name, :string, size: 30
      add :duration, :integer
      add :scored_at, :utc_datetime
    end

    create index("high_score", [:score])
    create index("high_score", [:scored_at])
  end
end
