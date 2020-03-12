defmodule NameGuess.DataSource.WikipediaPresidents do
  @moduledoc """
  Wikipedia POTUS

  Demo module
  """
  require Logger
  import NameGuess.DataSource, only: [index_with_reference: 1]
  alias NameGuess.Image
  alias NameGuess.Person

  @behaviour NameGuess.DataSource

  @source_base "https://en.wikipedia.org"
  @source_url @source_base <> "/wiki/List_of_presidents_of_the_United_States"
  @source "wikipedia_presidents"

  @impl true
  def get_name() do
    @source
  end

  @impl true
  def get() do
    with {:ok, presidents_raw} <- get_presidents() do
      presidents =
        presidents_raw
        |> get_real_picture_path()
        |> format_presidents()
        |> index_with_reference()

      Logger.info("Wikipedia datasource: #{Kernel.map_size(presidents)} presidents imported")

      {:ok, @source, presidents}
    else
      _ -> {:error, @source, nil}
    end
  end

  @impl true
  def import_image(president) do
    case HTTPoison.get(president.img_source) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        full_path = Image.get_picture_original_path(president)
        save_photo(full_path, body)

      _ ->
        {:error, nil}
    end
  end

  defp save_photo(path, content) do
    case File.write(path, content) do
      :ok ->
        {:ok, path}

      _ ->
        {:error, nil}
    end
  end

  defp get_real_picture_path(presidents) do
    presidents
    |> Enum.map(fn president ->
      case HTTPoison.get(@source_base <> president.picture) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          picture_url_full =
            body
            |> Floki.parse_document!()
            |> Floki.find("div.fullImageLink a")
            |> Floki.attribute("href")
            |> List.first()

          %{president | picture: "https:" <> picture_url_full}
      end
    end)
  end

  defp format_presidents(presidents) do
    Enum.map(presidents, fn president ->
      %Person{
        reference: Slug.slugify(president.name),
        name: president.name,
        gender: "male",
        division: president.party,
        position: "President of the United States",
        location: "USA",
        img_source: president.picture,
        source: @source
      }
    end)
  end

  defp get_presidents() do
    case HTTPoison.get(@source_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        presidents_nodes =
          body
          |> Floki.parse_document!()
          |> Floki.find("#toc + h2 + table.wikitable tr")
          |> Enum.drop(2)
          |> Enum.filter(fn {_, _, children} ->
            Kernel.length(children) > 4
          end)

        presidents =
          presidents_nodes
          |> Enum.map(fn {_, _, children} ->
            name =
              children
              |> Floki.raw_html()
              |> Floki.parse_document!()
              |> Floki.find("b a")
              |> Floki.text()

            picture_page =
              children
              |> Floki.raw_html()
              |> Floki.parse_document!()
              |> Floki.find("a.image")
              |> Floki.attribute("href")
              |> List.first()

            party =
              children
              |> Floki.raw_html()
              |> Floki.parse_document!()
              |> Floki.find("td")
              |> Enum.at(5)
              |> Floki.raw_html()
              |> Floki.parse_document!()
              |> Floki.find("a")
              |> List.first()
              |> Floki.text()
              |> String.replace(~r/\r|\n/, "")
              |> (fn text ->
                    if String.contains?(text, "["), do: nil, else: text
                  end).()

            %{name: name, party: party, picture: picture_page}
          end)

        {:ok, presidents}

      _ ->
        Logger.error("Error reaching Wikipedia's page")
        {:error, []}
    end
  end
end
