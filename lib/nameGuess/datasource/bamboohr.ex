defmodule NameGuess.DataSource.BambooHR do
  @moduledoc """
  BambooHR Api client
  """
  @behaviour NameGuess.DataSource

  require Logger
  import NameGuess.DataSource, only: [index_with_reference: 1]
  alias NameGuess.Image
  alias NameGuess.Person
  alias NameGuess.Space

  @endpoint "https://api.bamboohr.com/api/gateway.php/*SUBDOMAIN*/v1/"
  @source "bamboohr"

  @impl true
  def get_name() do
    @source
  end

  # -------------------- PEOPLE --------------------

  @impl true
  def get() do
    with {:ok, people_raw} <- list() do
      people =
        people_raw
        |> filter()
        |> as_struct()
        #        |> import_images()
        |> index_with_reference()

      Logger.info("BambooHR: #{Kernel.map_size(people)} people imported")

      {:ok, @source, people}
    else
      _ -> {:error, @source, nil}
    end
  end

  defp list() do
    {url, headers} = get_url()

    case HTTPoison.get(url <> "employees/directory", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        people =
          body
          |> Jason.decode!()
          |> Map.fetch!("employees")

        {:ok, people}

      _ ->
        {:error, []}
    end
  end

  defp filter(employees) do
    locations = Space.get_all_locations()

    employees
    |> Enum.reject(fn e ->
      (Map.get(e, "location") not in locations and Map.get(e, "location") != nil) or
        Map.get(e, "photoUploaded") == false or
        Map.get(e, "gender") == nil or
        Map.get(e, "workEmail") == nil
    end)
  end

  # Removes unnecessary fields
  defp as_struct(employees) do
    employees
    |> Enum.map(fn e ->
      photo_url =
        Map.get(e, "id")
        |> photo_url()

      gender =
        Map.get(e, "gender", "")
        |> String.downcase()

      %Person{
        reference: Map.get(e, "workEmail"),
        name: Map.get(e, "preferredName") || Map.get(e, "firstName"),
        gender: gender,
        division: Map.get(e, "department", nil),
        position: Map.get(e, "jobTitle", nil),
        location: Map.get(e, "location", nil),
        img_source: photo_url,
        source: @source
      }
    end)
  end

  # -------------------- PICTURES --------------------

  @impl true
  def import_image(employee) do
    {_url, headers} = get_url()

    case HTTPoison.get(employee.img_source, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        full_path = Image.get_picture_original_path(employee)
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

  defp photo_url(employee_id) do
    {url, _headers} = get_url()
    url <> "employees/#{employee_id}/photo/original"
  end

  # -------------------- UTILS --------------------

  defp get_url() do
    credentials =
      [Application.get_env(:nameGuess, :bamboohr_key), ":x"]
      |> List.to_string()
      |> Base.encode64()

    url =
      Application.get_env(:nameGuess, :bamboohr_subdomain)
      |> (&String.replace(@endpoint, "*SUBDOMAIN*", &1)).()

    {url, [{"Accept", "application/json"}, {"Authorization", "Basic #{credentials}"}]}
  end
end
