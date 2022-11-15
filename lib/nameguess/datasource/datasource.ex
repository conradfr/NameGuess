defmodule NameGuess.DataSource do
  alias NameGuess.Person

  @doc """
    Get module name
  """
  @callback get_name() :: String.t()

  @doc """
    Get all eligible people as a map of Person structs indexed by their id
  """
  @callback get() :: {atom, String.t(), %{integer => Person}}

  @doc """
    Store picture of a person
  """
  @callback import_image(person :: Person) :: {:ok, path :: String.t()} | {:error, nil}

  @spec index_with_reference(list(%Person{})) :: map
  def index_with_reference(people) do
    people
    |> Enum.reduce(%{}, fn e, acc ->
      Map.put(acc, e.reference, e)
    end)
  end

  @spec get_module_of_source(String.t()) :: module
  def get_module_of_source(source) do
    Application.get_env(:nameguess, :datasource_sources)
    |> Enum.find(fn module ->
      Kernel.apply(module, :get_name, []) == source
    end)
  end
end
