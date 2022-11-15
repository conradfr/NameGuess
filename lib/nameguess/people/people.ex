defmodule NameGuess.People do
  import Ecto.Query, only: [from: 2]
  alias NameGuess.Repo
  alias NameGuess.Cache
  alias NameGuess.{Space, Person, Person, Image}
  require Logger

  def get(ids)

  @spec get(integer) :: map
  def get(id) when is_integer(id) do
    case Cache.has_person(id) do
      true ->
        Cache.get_person(id)

      false ->
        person = Repo.get(Person, id)
        Cache.set_person(id, person)
        person
    end
  end

  # todo refactor for speed, look into ets match
  # ie https://elixirforum.com/t/best-way-to-get-multiple-keys-from-static-ets-table/23692
  @spec get(list(integer)) :: list
  def get(ids) when is_list(ids) do
    {cached, not_cached_keys} =
      ids
      |> Enum.reduce({[], []}, fn id, acc ->
        case Cache.has_person(id) do
          true ->
            person = Cache.get_person(id)
            cached = Kernel.elem(acc, 0) ++ [person]
            Kernel.put_elem(acc, 0, cached)

          false ->
            not_cached = Kernel.elem(acc, 1) ++ [id]
            Kernel.put_elem(acc, 1, not_cached)
        end
      end)

    unless length(not_cached_keys) == 0 do
      query =
        from(p in Person,
          where: p.id in ^not_cached_keys
        )

      not_cached_people = Repo.all(query)

      Cache.set_people(not_cached_people)
      not_cached_people ++ cached
    else
      cached
    end
  end

  # todo refactor all the ifs, add cache
  @spec get_keys(Space, atom()) :: list(integer)
  def get_keys(space \\ nil, gender \\ nil) do
    query =
      from(p in Person,
        select: [:id, :reference, :source]
      )

    query_gendered =
      case gender do
        nil ->
          query

        _ ->
          gender_string = Atom.to_string(gender)

          from(p in query,
            where: p.gender == ^gender_string
          )
      end

    # space filter locations
    query_locations =
      if space != nil and length(space.locations) > 0 do
        from(q in query_gendered,
          where: q.location in ^space.locations
        )
      else
        query_gendered
      end

    # space filter divisions
    query_divisions =
      if space != nil and length(space.divisions) > 0 do
        from(q in query_locations,
          where: q.division in ^space.divisions
        )
      else
        query_locations
      end

    Repo.all(query_divisions)
    |> filter_no_overloading(space)
    |> Enum.map(fn p -> p.id end)
  end

  @spec filter_no_overloading(list(Person), Space) :: map
  defp filter_no_overloading(people, space)

  defp filter_no_overloading(people, nil) do
    people
  end

  defp filter_no_overloading(people, %Space{hide_no_overloading: false} = _space) do
    people
  end

  defp filter_no_overloading(people, %Space{} = space) do
    Enum.filter(people, fn p ->
      Image.has_overloaded_picture?(space, p)
    end)
  end

  @spec get_keys_of_source(String.t()) :: list(tuple)
  def get_keys_of_source(source) do
    query =
      from(p in Person,
        select: [:id, :reference],
        where: p.source == ^source
      )

    Repo.all(query)
    |> Enum.map(fn p -> {p.id, p.reference} end)
  end

  @spec get_keys_total(Space, String.t()) :: integer
  def get_keys_total(space \\ nil, gender \\ nil)

  def get_keys_total(nil, _gender) do
    # not cached because only called on application start
    Repo.one(from(p in Person, select: count(p.id)))
  end

  def get_keys_total(%Space{} = space, nil) do
    case Cache.has_people_counter(space) do
      true ->
        Cache.get_people_counter(space)

      false ->
        count =
          get_keys(space)
          |> length()

        Cache.set_people_counter(count, space)
        count
    end
  end

  def get_keys_total(%Space{} = space, gender) do
    case Cache.has_people_counter(space, gender) do
      true ->
        Cache.get_people_counter(space, gender)

      false ->
        count =
          get_keys(space, String.to_atom(gender))
          |> length()

        Cache.set_people_counter(count, space, gender)
        count
    end
  end

  @spec random_keys(Space, number(), atom()) :: list(String.t())
  def random_keys(space, how_many, gender)

  def random_keys(%Space{} = space, 1, :all) do
    get_keys(space)
    |> Enum.random()
  end

  def random_keys(%Space{} = space, how_many, gender) do
    keys = get_keys(space, gender)

    picked =
      0..(how_many - 1)
      |> Enum.reduce([], fn _index, acc ->
        acc ++ [Enum.random(keys)]
      end)
      |> Enum.uniq()

    if length(picked) < how_many do
      picked ++ random_keys(space, how_many - length(picked), gender)
    else
      picked
    end
  end

  @spec get_divisions(Space) :: list(tuple)
  def get_divisions(%Space{} = space) do
    case Cache.has_divisions(space) do
      true ->
        Cache.get_divisions(space)

      false ->
        query =
          from(p in "person",
            where: not is_nil(p.division),
            select: p.division,
            distinct: true
          )

        # space filter divisions
        query =
          if length(space.divisions) > 0 do
            from(q in query,
              where: q.division in ^space.divisions
            )
          else
            query
          end

        # space filter locations
        query =
          if length(space.locations) > 0 do
            from(q in query,
              where: q.location in ^space.locations
            )
          else
            query
          end

        # Send the query to the repository
        divisions =
          Repo.all(query)
          |> Enum.sort()
          |> Enum.map(fn d ->
            {d, Slug.slugify(d)}
          end)

        Cache.set_divisions(space, divisions)
        divisions
    end
  end
end
