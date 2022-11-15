defmodule NameGuess.Space do
  import Ecto.Query, only: [from: 2]
  import Ecto.Changeset
  use Ecto.Schema
  alias NameGuess.Repo

  schema "space" do
    # tried using that as id instead of integer but got problem on migration so is extra field for now
    field(:codename, :string)
    field(:name, :string)
    field(:locations, {:array, :string}, default: [])
    field(:divisions, {:array, :string}, default: [])
    field(:public, :boolean)
    field(:display_position, :boolean, default: true)
    field(:hide_no_overloading, :boolean, default: false)
    field(:played, :integer, default: 0)
    field(:duration, :integer, default: 0)
    field(:timezone, :string, default: "Europe/Paris")
    field(:last_picked_state, {:array, :integer})
  end

  @doc false
  def update_picker_state(space, attrs \\ %{}) do
    space
    |> cast(attrs, [:last_picked_state])
    |> validate_required([:last_picked_state])
  end

  @spec increase_games_counter(__MODULE__) :: any
  def increase_games_counter(space) do
    Repo.query(
      """
      UPDATE space SET played = space.played + 1 WHERE id = $1;
      """,
      [space.id]
    )
  end

  @spec increase_duration_counter(__MODULE__, integer) :: any
  def increase_duration_counter(space, duration) do
    Repo.query(
      """
      UPDATE space SET duration = space.duration + $2 WHERE id = $1;
      """,
      [space.id, duration]
    )
  end

  @spec get_all_locations() :: list
  def get_all_locations() do
    query =
      from(s in __MODULE__,
        select: s.locations
      )

    Repo.all(query)
    |> Enum.reduce([], fn s, acc -> acc ++ s end)
    |> Enum.uniq()
  end

  def get_all() do
    Repo.all(__MODULE__)
  end
end
