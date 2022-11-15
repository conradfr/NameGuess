defmodule NameGuess.HighScore do
  use Ecto.Schema
  import Ecto.Changeset
  alias NameGuess.Space

  schema "high_score" do
    field(:score, :integer)
    field(:name, :string)
    field(:duration, :integer)
    field(:is_winner, :boolean, default: false)
    field(:scored_at, :utc_datetime)
    belongs_to(:space, Space)
  end

  @doc false
  def changeset(high_score, attrs) do
    high_score
    |> cast(attrs, [:name, :score, :duration, :scored_at, :space])
    |> validate_required([:name, :score, :duration, :space])
  end

  @doc false
  def changeset_form(high_score, attrs) do
    high_score
    |> cast(attrs, [:name])
    |> validate_required([:id, :name])
  end
end
