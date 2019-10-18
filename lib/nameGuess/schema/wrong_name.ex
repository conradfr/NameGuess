defmodule NameGuess.WrongName do
  use Ecto.Schema
  alias NameGuess.Person
  alias NameGuess.Space

  @primary_key false

  schema "wrong_name" do
    belongs_to(:space, Space, primary_key: true)
    belongs_to(:person, Person, primary_key: true)
    field(:name, :string, primary_key: true)
    field(:counter, :integer)
  end
end
