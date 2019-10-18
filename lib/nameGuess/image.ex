defmodule NameGuess.Image do
  import Ecto.Query, only: [from: 2]
  import Mogrify
  require Logger
  alias Ecto.UUID
  alias NameGuess.Repo
  alias NameGuess.Person

  @public_folder "priv/pics/"

  @people_origin_folder "priv/people_original/"
  @people_display_folder "priv/people_display/"
  @people_thumbnail_folder "people_thumbnail/"
  @people_overloading_folder "priv/people_overloading/"

  @cover_image_folder_temp "priv/cover_generate/"
  @cover_dest "home_gen.jpg"

  @cover_how_many 25..55
  @cover_height 720
  @cover_width 480

  @max_width_full 300
  @max_width_thumbnail 300

  # -------------------- Homepage generated image --------------------

  def homepage_path() do
    @public_folder <> @cover_dest
  end

  def homepage() do
    unless Mix.env() == :dev do
      # Delete previous slices (should be deleted anyway)
      delete_slices()

      how_many = Enum.random(@cover_how_many)
      slice_height = Kernel.trunc(@cover_height / how_many)

      how_many
      |> get_cover_files()
      |> slice(slice_height)

      assemble()
    end
  end

  defp get_cover_files(how_many) do
    #    File.ls!(@static_path <> @cover_source_folder)
    #    |> Enum.take_random(how_many)

    from(p in Person,
      select: {p.reference, p.source},
      where: p.location == "Paris"
    )
    |> Repo.all()
    |> Enum.take_random(how_many)
    |> Enum.map(fn p ->
      get_picture_filename(p) <> ".jpg"
    end)
  end

  defp slice(images, height, index \\ 0)

  defp slice([], _height, _index) do
    :ok
  end

  defp slice(images, height, index) do
    [image | tail] = images

    open(@people_origin_folder <> image)
    |> custom("crop", "#{@cover_width}x#{height}+0+#{index * height}")
    |> format("jpeg")
    |> save(path: @cover_image_folder_temp <> Integer.to_string(index + 1) <> ".jpg")

    slice(tail, height, index + 1)
  end

  defp assemble() do
    images =
      Path.wildcard(@cover_image_folder_temp <> "*.jpg")
      |> Enum.sort(
        &(String.to_integer(Path.basename(&1, ".jpg")) <=
            String.to_integer(Path.basename(&2, ".jpg")))
      )

    System.cmd("convert", ["-append"] ++ images ++ [@public_folder <> @cover_dest])
    delete_slices()
    :ok
  end

  defp delete_slices() do
    Path.wildcard(@cover_image_folder_temp <> "*.jpg")
    |> Enum.each(fn f -> File.rm!(f) end)
  end

  # -------------------- People's picture --------------------

  @spec generate_from_original(Person, String.t()) :: tuple()
  def generate_from_original(person, img_id \\ UUID.generate()) do
    crop_height = :rand.uniform(3) - 1
    crop_width = :rand.uniform(3) - 1

    save_path = get_picture_full_path(img_id)

    person
    |> get_picture_original_path()
    |> process_image(save_path, @max_width_full, crop_height, crop_width)

    generate_overloadings(person, crop_height, crop_width)

    {:ok, img_id}
  end

  @spec generate_overloadings(Person, integer, integer) :: any
  defp generate_overloadings(person, crop_height, crop_width) do
    @people_overloading_folder
    |> File.ls!()
    |> Enum.filter(fn entry ->
      (@people_overloading_folder <> entry)
      |> File.dir?()
    end)
    |> Enum.map(fn folder ->
      folder <> "/" <> person.source <> "_" <> person.reference <> ".jpg"
    end)
    |> Enum.filter(fn file ->
      (@people_overloading_folder <> file)
      |> File.exists?()
    end)
    |> Enum.each(fn file ->
      (@people_overloading_folder <> file)
      |> process_image(
        @people_display_folder <> file,
        @max_width_full,
        crop_height,
        crop_width
      )
    end)
  end

  @spec generate_thumbnail(Person) :: any
  def generate_thumbnail(person) do
    thumbnail_path = get_picture_thumbnail_path(person)

    person
    |> get_picture_original_path()
    |> process_image(thumbnail_path, @max_width_thumbnail)
  end

  @spec process_image(String.t(), String.t(), integer, integer, integer) :: any
  defp process_image(image_path, save_path, max_width, crop_height \\ 0, crop_width \\ 0) do
    image_path
    |> open()
    #    |> custom("resize", "#{new_width}x#{new_height} -quality 85 -density 72")
    #    |> resize("#{new_width}x#{new_height}")
    |> custom("colorspace", "RGB")
    |> resize_to_limit(max_width + crop_width + crop_height)
    |> custom("colorspace", "sRGB")
    |> custom("brightness-contrast", "+#{crop_width}x+#{crop_height}+0+0")
    |> custom("density", "72")
    |> quality("85")
    #    |> custom("crop", "#{new_width - crop_width}x#{new_height - crop_height}+0+0")
    |> custom("strip")
    |> format("jpeg")
    |> save(path: save_path)
  end

  # -------------------- Path utils --------------------

  @spec get_picture_filename(Person | map | tuple) :: String.t()

  def get_picture_filename(%Person{reference: reference, source: source} = _person) do
    get_picture_filename_format(reference, source)
  end

  def get_picture_filename({reference, source} = _person) do
    get_picture_filename_format(reference, source)
  end

  def get_picture_filename(%{"reference" => reference, "source" => source} = _person) do
    get_picture_filename_format(reference, source)
  end

  @spec get_picture_filename_format(String.t(), String.t()) :: String.t()
  defp get_picture_filename_format(reference, source) do
    source <> "_" <> reference
  end

  @spec get_picture_original_path(Person) :: String.t()
  def get_picture_original_path(person) do
    @people_origin_folder <> get_picture_filename(person) <> ".jpg"
  end

  @spec get_picture_full_path(String.t()) :: String.t()
  def get_picture_full_path(filename) do
    @people_display_folder <> filename <> ".jpg"
  end

  @spec get_picture_thumbnail_path(Person | map) :: String.t()
  def get_picture_thumbnail_path(person) do
    @public_folder <> @people_thumbnail_folder <> get_picture_filename(person) <> ".jpg"
  end

  @spec get_overloaded_picture_full_path(String.t(), Person) :: String.t()
  def get_overloaded_picture_full_path(space_codename, person) do
    @people_display_folder <>
      space_codename <> "/" <> person.source <> "_" <> person.reference <> ".jpg"
  end

  @spec has_overloaded_picture?(Space, Person) :: boolean
  def has_overloaded_picture?(space, person) do
    get_overloaded_picture_full_path(space.codename, person)
    |> File.exists?([:raw])
  end
end
