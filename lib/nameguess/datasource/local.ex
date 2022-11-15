defmodule NameGuess.DataSource.Local do
  @moduledoc """
  Local entries
  """
  require Logger
  import NameGuess.DataSource, only: [index_with_reference: 1]
  alias NameGuess.Image
  alias NameGuess.Person

  @behaviour NameGuess.DataSource

  @source_path "priv/data/datasource_local.json"
  @local_path "priv/pics_local/"
  @source "local"

  @impl true
  def get_name() do
    @source
  end

  @impl true
  def get() do
    people =
      list()
      |> index_with_reference()

    Logger.info("Local datasource: #{Kernel.map_size(people)} people imported")
    {:ok, @source, people}
  end

  defp list() do
    with {:ok, json} <- File.read(@source_path),
         {:ok, entries} <- Jason.decode(json, [{:keys, :atoms}]) do
      Enum.map(entries, fn entry ->
        %Person{
          reference: entry.reference,
          name: entry.name,
          gender: entry.gender,
          division: entry.division,
          position: entry.position,
          location: entry.location,
          img_source: entry.img_source,
          source: @source
        }
      end)
    else
      _ ->
        Logger.warn("Local datasource: importation failed")
        []
    end
  end

  @impl true
  def import_image(person) do
    with local_image <- image_full_local_path(person.img_source),
         dest_image <- Image.get_picture_original_path(person) do
      case File.copy(local_image, dest_image) do
        {:ok, _} ->
          {:ok, dest_image}

        {:error, reason} ->
          Logger.debug("Error copying image: #{reason}")
          {:error, nil}
      end
    end
  end

  defp image_full_local_path(img_source) do
    @local_path <> img_source <> ".jpg"
  end
end
