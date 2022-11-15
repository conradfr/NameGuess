defmodule NameGuess.People.Stats do
  @moduledoc """
  Stats about people

  Ranking lifted from:
  http://www.evanmiller.org/how-not-to-sort-by-average-rating.html
  https://gist.github.com/mbadolato/8253004
  """
  import Ecto.Query, only: [dynamic: 2]
  alias NameGuess.Repo
  alias NameGuess.Person
  alias NameGuess.PersonStats
  alias NameGuess.Space
  alias NameGuess.WrongName

  @number_of_stats 50
  @number_of_wrong_names 10

  @confidence 2.241403

  @spec get_most_guessed(Space, String.t(), integer) :: list(map)
  def get_most_guessed(%Space{} = space, division \\ nil, how_many \\ @number_of_stats) do
    {query, parameters} = guessed_query("guessed", space, division, how_many)
    {:ok, result} = Repo.query(query, parameters)
    map_query_result(result)
  end

  @spec get_least_guessed(Space, String.t(), integer) :: list(map)
  def get_least_guessed(%Space{} = space, division \\ nil, how_many \\ @number_of_stats) do
    {query, parameters} = guessed_query("not_guessed", space, division, how_many)
    {:ok, result} = Repo.query(query, parameters)
    map_query_result(result)
  end

  defp guessed_query(field, %Space{} = space, division, how_many) do
    field_full = "ps." <> field

    parameters = [@confidence, how_many, space.id]
    param_number_init = 3

    {and_where, param_number, parameters} =
      unless division == nil do
        {"and p.division = $" <> Integer.to_string(param_number_init + 1), param_number_init + 1,
         parameters ++ [division]}
      else
        {"", param_number_init, parameters}
      end

    {and_where, param_number, parameters} =
      unless length(space.locations) == 0 do
        {and_where <> " and p.location = ANY($" <> Integer.to_string(param_number + 1) <> ")",
         param_number + 1, parameters ++ [space.locations]}
      else
        {and_where, param_number, parameters}
      end

    {and_where, _param_number, parameters} =
      unless length(space.divisions) == 0 do
        {and_where <> " and p.division = ANY($" <> Integer.to_string(param_number + 1) <> ")",
         param_number + 1, parameters ++ [space.divisions]}
      else
        {and_where, param_number, parameters}
      end

    {"""
     SELECT p.id, p.reference, p.source, p.name, p.img, p.position, ps.guessed, ps.not_guessed, array_agg(wn.name order by wn.counter desc) as wrong_names,
     round(ps.guessed * 100 / (ps.guessed + ps.not_guessed), 0)::integer as percent_guessed,
     ((1.0 * #{field_full} / (ps.guessed + ps.not_guessed)) + $1::real * $1::real / (2 * (ps.guessed + ps.not_guessed)) - $1::real * SQRT(((1.0 * #{field_full} / (ps.guessed + ps.not_guessed)) * (1 - (1.0 * #{field_full} / (ps.guessed + ps.not_guessed))) + $1::real * $1::real / (4 * (ps.guessed + ps.not_guessed))) / (ps.guessed + ps.not_guessed))) / (1 + $1::real * $1::real / (ps.guessed + ps.not_guessed)) as final_score
     from person_stats ps
     inner join person p on ps.person_id = p.id
     left join wrong_name wn on p.id = wn.person_id and wn.space_id = $3
     where ps.space_id = $3 and (ps.guessed != 0 or ps.not_guessed != 0)
     #{and_where}
     group by p.id, p.name, ps.guessed, ps.not_guessed, p.img
     order by final_score desc, ps.guessed desc, ps.not_guessed asc, p.name asc
     limit $2
     """, parameters}
  end

  # todo refactor
  defp map_query_result(result) do
    result.rows
    |> Enum.map(fn row ->
      names =
        if Kernel.hd(Enum.at(row, 8)) == nil,
          do: [],
          else: Enum.at(row, 8) |> Enum.take(@number_of_wrong_names)

      %{
        Enum.at(result.columns, 0) => Enum.at(row, 0),
        Enum.at(result.columns, 1) => Enum.at(row, 1),
        Enum.at(result.columns, 2) => Enum.at(row, 2),
        Enum.at(result.columns, 3) => Enum.at(row, 3),
        Enum.at(result.columns, 4) => Enum.at(row, 4),
        Enum.at(result.columns, 5) => Enum.at(row, 5),
        Enum.at(result.columns, 6) => Enum.at(row, 6),
        Enum.at(result.columns, 7) => Enum.at(row, 7),
        Enum.at(result.columns, 8) => names,
        Enum.at(result.columns, 9) => Enum.at(row, 9)
      }
    end)
  end

  @spec has_been_guessed(Space, integer) :: tuple
  def has_been_guessed(%Space{} = space, person_id) do
    PersonStats.add_guessed(space.id, person_id)
    {:ok, nil}
  end

  @spec has_not_been_guessed(Space, String.t(), String.t()) :: tuple
  def has_not_been_guessed(%Space{} = space, correct_id, wrong_id) do
    person = Repo.get(Person, correct_id)

    PersonStats.add_not_guessed(space.id, correct_id)

    unless wrong_id == nil do
      wrong = Repo.get(Person, wrong_id)

      # we insert a new entry or increase the counter if this combination of id + name exists
      on_conflict = [set: [counter: dynamic([wn], fragment("? + ?", wn.counter, 1))]]

      {:ok, _updated} =
        Repo.insert(%WrongName{space: space, person: person, name: wrong.name, counter: 1},
          on_conflict: on_conflict,
          conflict_target: [:space_id, :person_id, :name]
        )
    end

    {:ok, nil}
  end
end
