defmodule NameGuess.Cache do
  @moduledoc """
  Simple cache to avoid repetitive trips to the datastore
  """
  require Logger
  use GenServer
  alias NameGuess.Space
  alias NameGuess.Person

  @name :cache

  # ---------- Client interface ----------

  def start_link(_arg) do
    Logger.info("Starting the cache process ...")
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  @spec set_person(String.t(), map()) :: atom()
  def set_person(key, person) do
    GenServer.cast(@name, {:set_person, key, person})
  end

  @spec set_people(list()) :: atom()
  def set_people(people) do
    GenServer.cast(@name, {:set_people, people})
  end

  @spec delete_person(String.t()) :: atom()
  def delete_person(key) do
    GenServer.cast(@name, {:del_person, key})
  end

  @spec delete_people(list(String.t())) :: atom()
  def delete_people(keys) do
    GenServer.cast(@name, {:del_people, keys})
  end

  @spec set_divisions(Space, list()) :: atom()
  def set_divisions(space, divisions) do
    atom_space = get_divisions_atom(space)
    GenServer.cast(@name, {:set_divisions, atom_space, divisions})
  end

  @spec delete_divisions() :: atom()
  def delete_divisions() do
    GenServer.cast(@name, :delete_divisions)
  end

  @spec set_counter(atom(), Integer) :: atom()
  def set_counter(key, count) do
    GenServer.cast(@name, {:set_counter, key, count})
  end

  @spec delete_counters() :: atom()
  def delete_counters() do
    GenServer.cast(@name, :delete_counters)
  end

  @spec increment_games_counter(Space) :: atom()
  def increment_games_counter(space) do
    GenServer.cast(@name, {:increment_game_counter, space})
  end

  # ---------- ETS outside genserver (has/get)----------

  @spec has_person(integer) :: boolean
  def has_person(id) do
    :ets.member(:people, id)
  end

  @spec get_person(integer) :: Person
  def get_person(id) do
    [{^id, person}] = :ets.lookup(:people, id)
    person
  end

  @spec has_people_counter(Space, String.t()) :: boolean
  def has_people_counter(space, gender \\ nil) do
    counter_atom = get_people_counter_atom(space, gender)
    :ets.member(:counter, counter_atom)
  end

  @spec get_people_counter(Space, String.t()) :: integer
  def get_people_counter(space, gender \\ nil) do
    counter_atom = get_people_counter_atom(space, gender)
    [{^counter_atom, count}] = :ets.lookup(:counter, counter_atom)
    count
  end

  @spec set_people_counter(integer, Space, String.t()) :: any
  def set_people_counter(count, space, gender \\ nil) do
    counter_atom = get_people_counter_atom(space, gender)
    set_counter(counter_atom, count)
  end

  @spec has_game_counter(Space) :: boolean
  def has_game_counter(space) do
    counter_atom = get_game_counter_atom(space)
    :ets.member(:counter, counter_atom)
  end

  @spec get_game_counter(Space) :: integer
  def get_game_counter(space) do
    counter_atom = get_game_counter_atom(space)
    [{^counter_atom, count}] = :ets.lookup(:counter, counter_atom)
    count
  end

  @spec set_game_counter(Space) :: any
  def set_game_counter(space) do
    counter_atom = get_game_counter_atom(space)
    set_counter(counter_atom, space.played)
  end

  @spec has_divisions(Space) :: boolean
  def has_divisions(space) do
    atom_space = get_divisions_atom(space)
    :ets.member(:divisions, atom_space)
  end

  @spec get_divisions(Space) :: list()
  def get_divisions(space) do
    atom_space = get_divisions_atom(space)
    [{^atom_space, divisions}] = :ets.lookup(:divisions, atom_space)
    divisions
  end

  # ---------- Utils ---------

  @spec get_game_counter_atom(Space) :: atom()
  def get_game_counter_atom(space) do
    ("games_" <> space.codename)
    |> String.to_atom()
  end

  @spec get_people_counter_atom(Space, String.t()) :: atom()
  def get_people_counter_atom(space, gender \\ nil)

  def get_people_counter_atom(space, nil) do
    space_codename = (space && space.codename) || "all"

    ("people_" <> space_codename)
    |> String.to_atom()
  end

  def get_people_counter_atom(space, gender) do
    space_codename = (space && space.codename) || "all"

    ("people_" <> space_codename <> "_" <> gender)
    |> String.to_atom()
  end

  @spec get_divisions_atom(Space) :: atom()
  def get_divisions_atom(space) do
    String.to_atom(space.codename)
  end

  # ---------- Server callbacks ----------

  def init(:ok) do
    :ets.new(:people, [:named_table, read_concurrency: true])
    :ets.new(:counter, [:named_table, read_concurrency: true])
    :ets.new(:divisions, [:named_table, read_concurrency: true])
    {:ok, nil}
  end

  def handle_cast({:set_person, key, person}, _state) do
    :ets.insert(:people, {key, person})
    {:noreply, nil}
  end

  def handle_cast({:set_people, people}, _state) do
    Enum.each(people, fn p ->
      :ets.insert(:people, {p.id, p})
    end)

    {:noreply, nil}
  end

  def handle_cast({:del_person, key}, _state) do
    :ets.delete(:people, key)
    {:noreply, nil}
  end

  def handle_cast({:del_people, keys}, _state) do
    Enum.each(keys, fn k ->
      :ets.delete(:people, k)
    end)

    {:noreply, nil}
  end

  def handle_cast({:set_divisions, atom_space, divisions}, _state) do
    :ets.insert(:divisions, {atom_space, divisions})
    {:noreply, nil}
  end

  def handle_cast(:delete_divisions, _state) do
    :ets.delete_all_objects(:divisions)
    {:noreply, nil}
  end

  def handle_cast({:set_counter, key, count}, _state) do
    :ets.insert(:counter, {key, count})
    {:noreply, nil}
  end

  # todo delete only people, or by type
  def handle_cast(:delete_counters, _state) do
    :ets.delete_all_objects(:counter)
    {:noreply, nil}
  end

  def handle_cast({:increment_game_counter, space}, _state) do
    counter_atom = get_game_counter_atom(space)

    if :ets.member(:counter, counter_atom) == true do
      :ets.update_counter(:counter, counter_atom, 1)
    end

    {:noreply, nil}
  end
end
