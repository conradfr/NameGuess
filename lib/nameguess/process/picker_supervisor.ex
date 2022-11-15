defmodule NameGuess.PickerSupervisor do
  use DynamicSupervisor
  require Logger
  alias NameGuess.Space
  alias NameGuess.Picker

  def start_link(init_arg) do
    Logger.info("Starting the picker supervisor ...")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(space) do
    DynamicSupervisor.start_child(__MODULE__, {Picker, [space]})
  end

  def start_children() do
    Space.get_all()
    |> Enum.each(fn space ->
      start_child(space)
    end)
  end

  # maybe refactor, doesn't feel like good elixir code
  def update_children() do
    spaces = Space.get_all()

    # pids that runs
    current_pickers_pid =
      Supervisor.which_children(__MODULE__)
      |> Enum.map(fn {_, pid, _, _} ->
        pid
      end)

    # {codenames, pids} that runs from all that will need to run
    {current_spaces_codenames, current_spaces_pids} =
      spaces
      |> Enum.reduce({[], []}, fn space, acc ->
        pid =
          space
          |> Picker.get_process_name()
          |> Process.whereis()

        case pid do
          nil ->
            acc

          _ ->
            {codenames, pids} = acc
            {codenames ++ [space.codename], pids ++ [pid]}
        end
      end)

    (current_pickers_pid -- current_spaces_pids)
    |> Enum.each(fn pid ->
      Logger.info("Terminating the picker process (#{inspect(pid)}).")
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end)

    spaces
    |> Enum.filter(fn space ->
      space.codename not in current_spaces_codenames
    end)
    |> Enum.each(fn space ->
      start_child(space)
    end)

    {:ok, nil}
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
