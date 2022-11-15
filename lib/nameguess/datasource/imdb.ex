defmodule NameGuess.DataSource.IMDB do
  @moduledoc """
  BambooHR Api client
  """
  @behaviour NameGuess.DataSource

  require Logger
  alias NameGuess.Image
  alias NameGuess.Person

  @source "imdb"

  @endpoint_base "https://www.imdb.com"
  @endpoint_seasons @endpoint_base <> "/title/*SEASON_ID*/episodes"
  @endpoint_episodes @endpoint_base <> "/title/*SHOW_ID*/"

  @impl true
  def get_name() do
    @source
  end

  @impl true
  def get() do
    try do
      actors =
        Application.get_env(:nameguess, :shows)
        |> get_shows_url()
        |> get_seasons_url()
        |> get_episodes_url()
        |> get_actors_and_characters
        |> Enum.uniq()
        |> fetch_actors()
        |> index_it()

      {:ok, @source, actors}
    rescue
      _ -> {:error, @source, []}
    end
  end

  @spec get_shows_url(list(String.t())) :: list(String.t())
  defp get_shows_url(shows) do
    Enum.map(shows, fn show ->
      String.replace(@endpoint_seasons, "*SEASON_ID*", show)
    end)
  end

  @spec get_seasons_url(list(String.t())) :: list(String.t())
  defp get_seasons_url(urls) do
    Enum.reduce(urls, [], fn url, acc ->
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          seasons =
            Floki.attribute(body, "select#bySeason option", "value")
            |> Enum.map(fn season -> url <> "?season=" <> season end)

          acc ++ seasons

        _ ->
          acc
      end
    end)
  end

  @spec get_episodes_url(list(String.t())) :: list(String.t())
  defp get_episodes_url(urls) do
    Enum.reduce(urls, [], fn url, acc ->
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          episodes =
            Floki.attribute(body, ".list_item > .image > a > div.hover-over-image", "data-const")
            |> Enum.map(fn episode_id ->
              String.replace(@endpoint_episodes, "*SHOW_ID*", episode_id)
            end)

          acc ++ episodes

        _ ->
          acc
      end
    end)
  end

  @spec get_actors_and_characters(list(String.t())) :: list(tuple())
  defp get_actors_and_characters(urls) do
    Enum.reduce(urls, [], fn url, acc ->
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          show =
            body
            |> Floki.attribute(".titleParent > a", "title")
            |> Floki.text()
            |> String.trim()

          actors =
            body
            |> Floki.find("#titleCast > .cast_list tr")
            |> Enum.reduce([], fn element, acc_page ->
              name =
                Floki.find(element, "td.character")
                |> Floki.text()
                |> String.trim()
                |> String.replace(~r/\r|\n\s+/, "")

              link =
                Floki.find(element, "td:nth-child(1) a")
                |> Floki.attribute("href")
                |> List.first()

              unless show == nil or name == "" or link == nil do
                person = %Person{
                  name: name,
                  division: show,
                  source: @source
                }

                length(acc_page)
                |> Integer.to_string()
                |> Logger.debug()

                acc_page ++ [{person, link}]
                #                acc_page
              else
                acc_page
              end
            end)

          (acc ++ actors)
          |> Enum.uniq()

        _ ->
          acc
      end
    end)
  end

  #  @spec fetch_actors()
  defp fetch_actors(urls) do
    Enum.reduce(urls, [], fn {person, url}, acc ->
      case HTTPoison.get(@endpoint_base <> url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          reference =
            body
            |> Floki.attribute("meta[property=pageId]", "content")
            |> List.first()
            |> String.trim()

          person =
            person
            |> Map.put(:reference, reference)
            |> get_actor_picture(body)
            |> get_actor_gender(body)

          unless person == nil do
            acc ++ [person]
          else
            acc
          end

        _ ->
          acc
      end
    end)
  end

  defp get_actor_picture(actor, body) do
    picture =
      Floki.attribute(body, "img#name-poster", "src")
      |> List.first()

    unless picture == nil do
      Map.put(actor, :img_source, picture)
    else
      nil
    end
  end

  defp get_actor_gender(nil, _body) do
    nil
  end

  defp get_actor_gender(actor, body) do
    gender =
      Floki.find(body, "#name-job-categories > a > .itemprop")
      |> Enum.map(fn e ->
        Floki.text(e)
        |> String.trim()
      end)
      |> Enum.find(nil, fn job ->
        job in ["Actor", "Actress"]
      end)

    case gender do
      "Actor" -> Map.put(actor, :gender, "male")
      "Actress" -> Map.put(actor, :gender, "female")
      _ -> nil
    end
  end

  defp index_it(people) do
    people
    |> Enum.reduce(%{}, fn person, acc ->
      Map.put(acc, person.reference, person)
    end)
  end

  @impl true
  def import_image(person) do
    case HTTPoison.get(person.img_source) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        full_path = Image.get_picture_original_path(person)

        case File.write(full_path, body) do
          :ok ->
            {:ok, full_path}

          _ ->
            {:error, nil}
        end

      _ ->
        {:error, nil}
    end
  end
end
