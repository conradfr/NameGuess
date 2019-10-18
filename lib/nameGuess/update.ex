defmodule NameGuess.Update do
  require Logger
  alias NameGuess.PickerSupervisor
  alias NameGuess.People
  alias NameGuess.Cache
  alias NameGuess.Picker
  alias NameGuess.Image

  @doc """
    Check at startup, get data if none
  """
  def startup() do
    # Start pickers
    PickerSupervisor.start_children()

    if People.get_keys_total() == 0 do
      Logger.info("No people at startup, launching update ...")
      people()
    end

    if File.exists?(Image.homepage_path()) == false do
      Logger.info("No homepage image generated, launching creation ...")
      Image.homepage()
    end

    {:ok, nil}
  end

  @doc """
    Update pickers genservers
  """
  @spec pickers() :: tuple
  def pickers() do
    PickerSupervisor.update_children()
  end

  @doc """
    Add/update/delete people's entries
  """
  @spec people() :: tuple
  def people() do
    Logger.info("Updating people ...")

    how_many =
      Application.get_env(:nameGuess, :datasource_sources)
      |> process_sources()

    # Used by picker process for global rotation
    Picker.update_total_people()

    Cache.delete_counters()
    Cache.delete_divisions()

    Logger.info("Update done (#{how_many})")
    {:ok, how_many}
  end

  @doc """
   Update person's pictures
  """
  def pictures() do
    Logger.info("Updating people's pictures")

    People.get_keys()
    |> People.Store.update_pictures()
  end

  @spec process_sources(list(%{integer => Person}), integer) :: integer
  defp process_sources(sources, acc \\ 0)

  defp process_sources([], acc) do
    acc
  end

  defp process_sources(sources, acc) do
    [head | tail] = sources
    head_data = Kernel.apply(head, :get, [])

    case head_data do
      {:ok, source, people} ->
        parsed = process_source(source, people)
        process_sources(tail, acc + parsed)

      {:error, _, _} ->
        process_sources(tail, acc)
    end
  end

  @spec process_source(String.t(), list(%{integer => Person})) :: integer
  defp process_source(source, people) do
    people_references = Map.keys(people)
    old_keys = People.get_keys_of_source(source)

    old_keys_references =
      old_keys
      |> Enum.map(fn {_id, reference} ->
        reference
      end)

    {ids_to_delete, references_to_delete} =
      old_keys
      |> Enum.filter(fn {_id, reference} ->
        reference not in people_references
      end)
      |> Enum.reduce({[], []}, fn {id, reference}, {ids, references} ->
        {ids ++ [id], references ++ [reference]}
      end)

    references_to_add =
      people_references
      |> Enum.filter(fn reference ->
        reference not in old_keys_references
      end)

    references_to_update = old_keys_references -- references_to_delete

    People.Store.delete(ids_to_delete)
    {:ok, really_added} = People.Store.add(references_to_add, people)
    really_updated = People.Store.update(references_to_update, people)

    Picker.remove_from_picked(ids_to_delete)

    Logger.info(
      "Update #{source}: added  #{really_added}/#{length(references_to_add)}, removed: #{
        length(ids_to_delete)
      }, updated: #{really_updated}/#{length(references_to_update)}"
    )

    length(people_references)
  end
end
