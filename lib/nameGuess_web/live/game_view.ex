defmodule NameGuessWeb.GameView do
  use Phoenix.LiveView
  alias NameGuess.Game
  alias NameGuess.HighScore
  require Logger

  @next_interval_guessed 700
  @next_interval_wrong 1350

  def render(assigns) do
    NameGuessWeb.PageView.render("game.html", assigns)
  end

  def mount(session, socket) do
    if connected?(socket) do
      socket =
        socket
        |> assign(
          name_saved: Map.get(session.cookies, "name", ""),
          space: session.space,
          # potential bug if connected without reloading the page when people are updated
          guesses_to_win: session.number_of_people
        )
        |> start_game()
        |> schedule_end_of_countdown()

      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  defp start_game(socket) do
    Logger.info("(#{socket.assigns.space.codename}) Starting a new game")
    assign(socket, game: Game.new(socket.assigns.space), submit_score: nil, changeset: nil)
  end

  # -------------------- TICK --------------------

  defp schedule_end_of_countdown(socket) do
    game = socket.assigns.game
    timer = Process.send_after(self(), :end_of_countdown_end, game.countdown_from * 1000)
    updated = %{game | countdown_timer: timer}
    assign(socket, game: updated)
  end

  def handle_info(:end_of_countdown_end, socket) do
    game = Game.end_of_countdown(socket.assigns.game)

    case game do
      %{:state => state} when state == :gameover_next ->
        Process.send_after(self(), :tick_state, @next_interval_wrong)
        {:noreply, assign(socket, game: game)}

      _ ->
        {:noreply, assign(socket, game: game)}
    end
  end

  def handle_info(:tick_state, socket) do
    game = Game.next_state(socket.assigns.game)

    if Enum.member?([:win, :gameover], game.state) do
      high_score =
        case Map.has_key?(socket.assigns, :name_saved) do
          true -> %HighScore{name: socket.assigns.name_saved}
          false -> %HighScore{}
        end

      submit_state =
        case String.length(Map.get(socket.assigns, :name_saved, "")) > 0 do
          true -> :ok
          false -> :ko
        end

      socket =
        assign(socket, %{
          game: game,
          changeset: HighScore.changeset_form(high_score, %{name: socket.assigns.name_saved}),
          submit_score_allowed: submit_state
        })

      {:noreply, socket}
    else
      socket = assign(socket, game: game)

      if game.state == :ok do
        socket = schedule_end_of_countdown(socket)
        {:noreply, socket}
      else
        {:noreply, socket}
      end
    end
  end

  # -------------------- UI EVENTS --------------------

  def handle_event("start", _value, socket) do
    socket =
      start_game(socket)
      |> schedule_end_of_countdown()

    {:noreply, socket}
  end

  def handle_event("guess", %{"choice" => value}, socket) do
    game = Game.guess(socket.assigns.game, String.to_integer(value))
    Logger.debug("Guess")

    next_interval =
      case game.state do
        :ok_next ->
          @next_interval_guessed

        _ ->
          @next_interval_wrong
      end

    Process.send_after(self(), :tick_state, next_interval)

    {:noreply, assign(socket, game: game)}
  end

  def handle_event("name_change", %{"high_score" => high_score}, socket) do
    submit_state =
      case String.length(high_score["name"]) > 0 do
        true -> :ok
        false -> :ko
      end

    {:noreply, assign(socket, submit_score_allowed: submit_state)}
  end

  def handle_event("submit_best", %{"high_score" => high_score}, socket) do
    name = Map.get(high_score, "name")
    game = Game.add_best(socket.assigns.game, name)
    Logger.info("Submit high score: (#{socket.assigns.space.codename}) #{name} - #{game.score}")
    {:noreply, assign(socket, game: game, name: name, name_saved: name, submit_score: :ok)}
  end
end
