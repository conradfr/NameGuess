defmodule NameGuess.PictureRotate do
  @moduledoc """
  Rename a person's public picture file as a basic anti-cheat as you then can't map a picture to an id
  Image is also now modified each time from original to avoid mapping the binary to an id

  Renaming is done in two parts : first copying the file and updating the datastore with the new file name,
  and later deleting the old file. This is to avoid basic race condition with the picker / game,
  but it may be needed to be revisited later.
  """

  use GenServer
  require Logger
  alias NameGuess.Repo
  alias NameGuess.Cache
  alias NameGuess.Image
  alias NameGuess.Person

  @name :image_rotater
  @delay 120_000

  # ---------- Client interface ----------

  def start_link(_arg) do
    Logger.info("Starting the image rotate process ...")
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  @doc """
  Rotate a person's picture file

  ## Parameters

    - id: integer that represents the id of the person in db
  """
  @spec rotate(Person) :: atom()
  def rotate(person) do
    GenServer.cast(@name, {:rotate, person})
  end

  # ---------- Server callbacks ----------

  def init(:ok) do
    Process.flag(:trap_exit, true)
    {:ok, []}
  end

  def handle_cast({:rotate, person}, state) do
    full_path_current = Image.get_picture_full_path(person.img)

    #      case Image.generate_from_original(person) do
    new_state =
      case Image.generate_from_original(person, person.img) do
        {:ok, _new_image_id} ->
          # We currently disable the name rotation as we display them as base64 over the websocket
          # as a test before deciding between the two methods

          #          with_new_image = %{person | img: new_image_id}
          #
          #          changeset = Person.update_image_changeset(person, Map.from_struct(with_new_image))
          #          {:ok, updated} = Repo.update(changeset)
          #
          #          Cache.set_person(person.id, updated)
          #          Process.send_after(self(), {:delete, full_path_current}, @delay)
          #          Logger.debug("Picture for ##{person.id} copied")
          #
          #          state ++ [full_path_current]
          state

        {:error, reason} ->
          Logger.warn("Error copying picture of ##{person.id}: #{reason} ")
          state
      end

    {:noreply, new_state}
  end

  def handle_info({:delete, path}, state) do
    delete_file(path)
    new_state = state -- [path]
    {:noreply, new_state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def terminate(_, state) do
    Enum.each(state, fn f -> delete_file(f) end)
  end

  # ---------- Internal ----------

  defp delete_file(path) do
    case File.rm(path) do
      :ok ->
        Logger.debug("Picture file #{path} deleted")

      {:error, reason} ->
        Logger.warn("Error deleting picture file #{path}: #{reason} ")
    end
  end
end
