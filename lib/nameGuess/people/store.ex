defmodule NameGuess.People.Store do
  import Ecto.Query, only: [from: 2]
  alias NameGuess.TaskSupervisor
  alias NameGuess.DataSource
  alias NameGuess.People
  alias NameGuess.Cache
  alias NameGuess.Image
  alias NameGuess.Repo
  alias NameGuess.Person
  require Logger

  @task_timeout 120_000

  # -------------------- ADD --------------------

  @spec add(list(String.t()), map) :: tuple()
  def add(keys, all_people)

  def add([], _people) do
    {:ok, 0}
  end

  # todo parallelize with Flow
  def add(keys, all_people) do
    # we filter people which photo fails to be downloaded
    new_people_with_photo =
      all_people
      |> Map.take(keys)
      |> Enum.reduce([], fn {_id, person}, acc ->
        case import_image(person) do
          {:ok, _} ->
            case Image.generate_from_original(person) do
              {:ok, photo_id} ->
                Image.generate_thumbnail(person)
                updated_person = %{person | img: photo_id}
                acc ++ [updated_person]

              _ ->
                Logger.warn("Error generating image", [person: person])
                acc
            end

          {:error, _} ->
            Logger.warn("Error importing image", [person: person])
            acc
        end
      end)

    added =
      new_people_with_photo
      |> Enum.reduce(0, fn p, acc ->
        case Repo.insert(p) do
          {:ok, _} ->
            acc + 1

          {:error, _} ->
            p.id
            |> Image.get_picture_original_path()
            |> File.rm!()

            acc
        end
      end)

    {:ok, added}
  end

  @spec import_image(Person) :: tuple()
  defp import_image(person) do
    DataSource.get_module_of_source(person.source)
    |> Kernel.apply(:import_image, [person])
  end

  # -------------------- DELETE --------------------

  @spec delete(list(Integer)) :: tuple()
  def delete(keys)

  def delete([]) do
    {:ok, 0}
  end

  def delete(keys) do
    # delete pictures
    keys
    |> People.get()
    |> Enum.each(fn person ->
      Map.get(person, :img)
      |> Image.get_picture_full_path()
      |> File.rm()

      person
      |> Image.get_picture_thumbnail_path()
      |> File.rm()

      person
      |> Image.get_picture_original_path()
      |> File.rm()
    end)

    Cache.delete_people(keys)
    {deleted, _} = from(p in Person, where: p.id in ^keys) |> Repo.delete_all()

    {:ok, deleted}
  end

  # -------------------- UPDATE --------------------

  @spec update(list(String.t()), map) :: tuple()
  def update(references, all_people)

  def update(%{}, _) do
    {:ok, 0}
  end

  def update(references, all_people) do
    all_people
    |> Map.take(references)
    |> Enum.reduce(0, fn {reference, person}, acc ->
      db_person = Repo.get_by(Person, reference: reference, source: person.source)

      unless db_person == nil do
        changeset = Person.update_changeset(db_person, Map.from_struct(person))

        case Repo.update(changeset) do
          {:ok, _} -> acc + 1
          {:error, _} -> acc
        end
      else
        acc
      end
    end)
  end

  # todo parallelize
  def update_pictures(ids) do
    ids
    |> Enum.each(fn id ->
      person = Repo.get(Person, id)

      unless person == nil do
        update_pictures_task =
          Task.Supervisor.async_nolink(TaskSupervisor, fn ->
            import_image(person)
            Image.generate_from_original(person, person.img)
            Image.generate_thumbnail(person)
            Logger.info("Image imported #{Integer.to_string(person.id)} #{person.img} ")
          end)

        Task.await(update_pictures_task, @task_timeout)
      end
    end)
  end
end
