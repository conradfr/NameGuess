defmodule NameGuess.Picker do
  use GenServer
  alias NameGuess.People
  alias NameGuess.Repo
  alias NameGuess.Space
  require Logger

  @name_prefix "pick_server_"

  @delay_save 1000

  @choices_per_round [
    {0..0, 2},
    {1..1, 3},
    {2..9, 4},
    {10..19, 6},
    {20..34, 8},
    {35..49, 10},
    {50..64, 12},
    {65..79, 14},
    {80..99, 16},
    {100..124, 18},
    {125..199, 20},
    {200..249, 22},
    {250..349, 24},
    {350..449, 28},
    {450..5000, 30}
  ]

  # ---------------  Client interface ---------------

  def start_link([space]) do
    Logger.info("Starting the picker process (#{space.codename}) ...")
    GenServer.start_link(__MODULE__, [space], name: get_process_name(space))
  end

  @spec pick_next_round(Space, list(String.t()), integer) :: tuple
  def pick_next_round(space, previous_picks \\ [], round \\ 1) do
    GenServer.call(get_process_name(space), {:pick_next_round, previous_picks, round})
  end

  @spec update_total_people() :: any
  def update_total_people() do
    NameGuess.PickerSupervisor
    |> Supervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} ->
      GenServer.cast(pid, :update_total_people)
    end)
  end

  @doc """
    Delete removed people from all pickers
  """
  @spec remove_from_picked(list(String.t())) :: any
  def remove_from_picked(ids) do
    NameGuess.PickerSupervisor
    |> Supervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} ->
      GenServer.cast(pid, {:remove_from_picked, ids})
    end)
  end

  @spec get_process_name(Space) :: atom
  def get_process_name(space) do
    (@name_prefix <> space.codename)
    |> String.to_atom()
  end

  # ---------------  Server callbacks ---------------

  @impl true
  def init([space]) do
    last_picked = space.last_picked_state || []
    total_people = People.get_keys_total(space)

    Process.flag(:trap_exit, true)
    {:ok, {space, last_picked, total_people}}
  end

  @impl true
  def handle_call(
        {:pick_next_round, previous_picks, round},
        _from,
        {space, global_picks, max} = _state
      ) do
    all_previous_picks =
      [previous_picks | global_picks]
      |> List.flatten()
      |> Enum.uniq()

    # if current game picks + all picks in current rotation exceed capacity
    # we avoid the risk of not be able to pick someone by dismissing global picks
    next_pick =
      case People.get_keys_total(space) <= length(all_previous_picks) do
        true ->
          pick_next(space, previous_picks)

        false ->
          pick_next(space, all_previous_picks)
      end

    next_pick_gender = String.to_atom(next_pick.gender)
    max_with_gender = People.get_keys_total(space, next_pick.gender)

    # we make sure there is enough people of this gender for the number of choices
    # or just put the max possible
    how_many =
      case how_many_choices(round) do
        number when number <= max_with_gender ->
          number

        _ ->
          max_with_gender
      end

    next_set =
      pick(space, how_many, next_pick_gender, [next_pick])
      |> Enum.sort_by(fn person -> person.name end)

    new_global_picks = [next_pick.id | global_picks]
    Process.send_after(self(), :save_picked, @delay_save)

    # if everyone has been picked, start a new cycle
    if length(new_global_picks) >= max do
      Logger.info("(#{space.codename}) Everybody has been picked, resetting.")
      {:reply, {next_pick, next_set}, {space, [], max}}
    else
      {:reply, {next_pick, next_set}, {space, new_global_picks, max}}
    end
  end

  @impl true
  def handle_cast(:update_total_people, {space, global_picks, _max} = _state) do
    new_total = People.get_keys_total(space)
    {:noreply, {space, global_picks, new_total}}
  end

  @doc """
    Removes deleted people from global pick to avoid faulty rotation

    Leaves a potential bug for now if deleted people has been picked in a current game (wrong win),
    but as we update during the night that should be enough

    todo: we could send an update message to the current games process (game_view.ex)
  """
  @impl true
  def handle_cast({:remove_from_picked, ids}, {space, global_picks, max} = _state) do
    {:noreply, {space, global_picks -- ids, max}}
  end

  @impl true
  def handle_info(:save_picked, {space, global_picks, _max} = state) do
    save_picked_state(space, global_picks)
    {:noreply, state}
  end

  @impl true
  def terminate(_, {space, global_picks, _max} = state) do
    save_picked_state(space, global_picks)
    {:noreply, state}
  end

  # ---------- Internal ----------

  @spec save_picked_state(Space, list(integer)) :: tuple
  defp save_picked_state(space, picked) do
    changeset = Space.update_picker_state(space, %{last_picked_state: picked})
    Repo.update(changeset)
  end

  @spec pick_next(Space, list(String.t())) :: map
  defp pick_next(space, past_picks) do
    pick_unique(space, past_picks)
    |> People.get()
  end

  @spec pick_unique(Space, list(String.t())) :: String.t()
  defp pick_unique(space, past_picks) do
    picked = People.random_keys(space, 1, :all)

    if Enum.member?(past_picks, picked) do
      pick_unique(space, past_picks)
    else
      picked
    end
  end

  @spec pick(Space, integer, atom, list(String.t())) :: list
  defp pick(space, how_many, gender, already_picked)

  defp pick(_space, 0, _gender, already_picked) do
    already_picked
  end

  defp pick(space, how_many, gender, already_picked) do
    picked =
      pick_rand(space, how_many - length(already_picked), gender)
      |> People.get()
      |> (fn new -> already_picked ++ new end).()
      |> Enum.uniq_by(fn person ->
        person.name
        |> WordSmith.remove_accents()
      end)

    if length(picked) < how_many do
      pick(space, how_many, gender, picked)
    else
      picked
    end
  end

  defp pick_rand(space, how_many, gender) do
    People.random_keys(space, how_many, gender)
  end

  defp how_many_choices(round) do
    Enum.find_value(@choices_per_round, fn {range, how_many} ->
      if Enum.member?(range, round) do
        how_many
      end
    end)
  end
end
