defmodule NameGuessWeb.PageView do
  use NameGuessWeb, :view
  require Logger
  alias NameGuess.Score
  alias NameGuess.Game
  alias NameGuess.Image
  alias NameGuess.People.Store

  def countdown_state(_conn, game) do
    cond do
      Enum.member?([:ok], game.state) == true -> "start"
      true -> "stop"
    end
  end

  def game_state_class(_conn, game) do
    if game.state in [:ok, :win, :gameover] do
      "state-" <> Atom.to_string(game.state)
    else
      ""
    end
  end

  def button_state_class(_conn, game, id) do
    pick_id = game.current_pick.id

    cond do
      Enum.member?([:ok_next, :win_next], game.state) == true and
          pick_id == id ->
        "success"

      Enum.member?([:gameover_next], game.state) == true and
          game.wrong_pick == id ->
        "alert"

      Enum.member?([:gameover_next], game.state) == true and
          pick_id == id ->
        "primary"

      true ->
        "secondary"
    end
  end

  def is_high_score?(%{score: 0} = _game) do
    false
  end

  def is_high_score?(game) do
    duration = Game.get_duration(game)
    Score.is_high_score?(game.space, game.score, duration)
  end

  def thumbnail_path(person) do
    "/pics/people_thumbnail/" <> Image.get_picture_filename(person) <> ".jpg"
  end

  def game_encoded_picture(space_codename, person) do
    overloading_path = Image.get_overloaded_picture_full_path(space_codename, person)

    image_path =
      if File.exists?(overloading_path) == true do
        overloading_path
      else
        Image.get_picture_full_path(person.img)
      end

    case File.read(image_path) do
      {:ok, image} ->
        Base.encode64(image)

      {:error, reason} ->
        Logger.warn("Error reading #{Integer.to_string(person.id)} #{image_path} : #{reason}")
        Store.update_pictures(person.id)
        "error"
    end
  end
end
