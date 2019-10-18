defmodule NameGuess.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "person" do
    field(:reference, :string)
    field(:division, :string)
    field(:gender, :string)
    field(:img, :string)
    field(:img_source, :string)
    field(:name, :string)
    field(:position, :string)
    field(:location, :string)
    field(:source, :string)
    has_many(:wrong_names, NameGuess.WrongName)
    has_many(:person_stats, NameGuess.PersonStats)

    timestamps()
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [
      :reference,
      :name,
      :gender,
      :division,
      :position,
      :img,
      :img_source,
      :location,
      :source
    ])
    |> validate_required([:reference, :name, :gender, :img, :img_source, :source])
  end

  @doc false
  def update_changeset(person, attrs \\ %{}) do
    person
    |> cast(attrs, [
      :reference,
      :name,
      :gender,
      :img_source,
      :division,
      :position,
      :location,
      :source
    ])
    |> validate_required([:id, :reference, :name, :gender, :img, :img_source, :source])
  end

  @doc false
  def update_image_changeset(person, attrs \\ %{}) do
    person
    |> cast(attrs, [:img])
    |> validate_required([:id, :reference, :name, :gender, :img, :img_source, :source])
  end
end
