defmodule NameGuessWeb.GameLive do
  require Logger
  use NameGuessWeb, :live_view
  alias NameGuess.{Game, HighScore, Image, Score, People}
  alias NameGuess.People.Store

  @next_interval_guessed 700
  @next_interval_wrong 1350

  @impl true
  def render(assigns) do
    ~H"""
      <%= if @game != nil do %>
      <div class={"grid-x grid-padding-x #{game_state_class(@socket, @game)}"} id="game-hook" phx-hook="Game">
        <div class="cell small-5 medium-3 text-center">
          <div class="pick-img">
              <img alt="Who dis?" title="Who dis?" src={"data:image/jpg;base64, #{game_encoded_picture(@game.space.codename, @game.current_pick)}"}>
              <p :if={@space.display_position == true} class="job"><%= @game.current_pick.position %></p>
          </div>
          <div class="game-info-small show-for-small-only">
            <div class="countdown-label"><%= gettext "Countdown" %></div>
            <div class="countdown"><%= @game.tick %></div>
            <div class="score-label"><%= gettext "Score" %></div>
            <div class="score"><%= @game.score %></div>
          </div>
        </div>
        <div class="cell auto text-center">
          <div class="grid-x grid-padding-x live-header hide-for-small-only">
            <div class="cell medium-6 game-info-medium">
              <span class="countdown-label"><%= gettext "Countdown" %>:</span> <span id="desktop-countdown" class="countdown" phx-hook="Countdown" data-state={countdown_state(@socket, @game)} data-countdown={@game.countdown_from}><%= @game.tick %></span>
            </div>
            <div class="cell medium-6 game-info-medium">
              <span class="score-label"><%= gettext "Score" %>:</span>&nbsp;<span class="score"><%= @game.score %></span> <span class="score-to-win">/<%= @guesses_to_win %></span>
            </div>
          </div>

        <%= if Enum.member?([:ok, :ok_next, :win_next, :gameover_next], @game.state) do %>
          <div class="grid-x grid-padding-x">
            <div class="cell auto">
            <%= for choice <- @game.current_choices do %>
                <%= if @game.state == :ok do %>
                  <button class="button-choice button secondary" phx-click="guess" phx-value-choice={choice.id}>
                    <%= choice.name %>
                  </button>
                <% else %>
                  <button class={"button-choice no-click button #{button_state_class(@socket, @game, choice.id)}"}>
                    <%= choice.name %>
                  </button>
                <% end %>
            <% end %>
            </div>
          </div>
        <% end %>

        <%= if @game.state == :gameover or @game.state == :win do %>
          <div class="grid-x grid-padding-x align-center-middle text-center game-over-container">
            <div class="cell auto">
              <h3 :if={@game.state == :gameover} class="text-center game-over-text"><%= gettext "Game over :(" %></h3>
              <h3 :if={@game.state == :win} class="text-center game-win-text"><%= gettext "YOU WIN !" %></h3>
            </div>
          </div>
          <div class="grid-x grid-padding-x game-over-score-container">
            <div class="cell small-12 auto game-over-score">
              <p class="text-center"><%= gettext "Final score" %>: <span class="game-over-score-label"><%= @game.score %></span></p>
            </div>
          </div>

          <%= if is_high_score?(@game) == true do %>
          <div class="grid-x grid-padding-x game-over-highscore-container">
            <div class="cell medium-8 medium-offset-2 small-12">
            <%= if assigns[:submit_score] == nil do %>
              <.form let={f} for={@changeset} phx-submit="submit_best" phx-change="name_change" autocomplete="off">
                <div class="grid-x grid-padding-x">
                  <div class="small-6 medium-3 medium-offset-2 cell">
                    <label class="text-left"><%= gettext "Save your score" %>:</label>
                  </div>
                  <div class="small-6 medium-5 cell">
                    <div class="float-right">
                    <%= gettext("#%{rank} this month", rank: @game.score_rank_this_month) %>
                    <%= if @game.score_rank_all_time < 26 do %>
                      <%= gettext(", #%{rank} overall", rank: @game.score_rank_all_time) %>
                    <% end %>
                    </div>
                  </div>
                </div>
                <div class="grid-x grid-padding-x">
                  <div class="small-auto medium-8 medium-offset-2 cell">
                    <div class="input-group">
                      <%= text_input f, :name, [{"placeholder", "Your name"}, {"class", "input-group-field"}] %>
                      <div class="input-group-button">
                        <button type="submit" class={"button success#{if assigns[:submit_score_allowed] != :ok, do: " disabled"}"} phx-disable-with="Saving..."><%= gettext "Submit" %></button>
                      </div>
                    </div>
                  </div>
                </div>
              </.form>
            <% end %>
            <%= if assigns[:submit_score] != nil and @submit_score == :ok do %>
              <div class="text-center score-updated" data-name={@name}>
                  <i class="fi-check"></i> <%= gettext "Score registered" %> - <a href={Routes.page_path(@socket, :high_scores, @game.space.codename)}><%= gettext "Check high scores" %></a>
              </div>
            <% end %>
            </div>
          </div>
          <% else %>
            <div if={@game.score == 0} class="grid-x grid-padding-x text-center">
              <div class="cell auto">
                <img title="Ahah!" alt="Ahah!" style="height: 85px" src={Routes.static_path(@socket, "/images/loser.png")}>
              </div>
            </div>
          <% end %>

          <div class="grid-x grid-padding-x">
            <div class="cell medium-offset-3 medium-6">
              <button class="button text-center expanded play-again" phx-click="start"><%= gettext "Play again !" %></button>
            </div>
          </div>
        <% end %>
        </div>
      </div>
      <% end %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      socket =
        socket
        |> assign(
          name_saved: Map.get(session, "name", ""),
          space: session["space"],
          # potential bug if connected without reloading the page when people are updated
          guesses_to_win: People.get_keys_total(session["space"])
        )
        |> start_game()
        |> schedule_end_of_countdown()

      {:ok, socket}
    else
      {:ok, assign(socket, game: nil)}
    end
  end

  defp start_game(socket) do
    Logger.info("(#{socket.assigns.space.codename}) Starting a new game")
    assign(socket, game: Game.new(socket.assigns.space), submit_score: nil, changeset: nil)
  end

  # -------------------- TICK --------------------

  defp schedule_end_of_countdown(%{assigns: %{game: game}} = socket) do
    timer = Process.send_after(self(), :end_of_countdown_end, game.countdown_from * 1000)

    socket
    |> assign(game: %{game | countdown_timer: timer})
  end

  @impl true
  def handle_info(:end_of_countdown_end, socket) do
    game = Game.end_of_countdown(socket.assigns.game)

    if game.state == :gameover_next,
      do: Process.send_after(self(), :tick_state, @next_interval_wrong)

    {:noreply, assign(socket, game: game)}
  end

  @impl true
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

      {:noreply,
       assign(socket, %{
         game: game,
         changeset: HighScore.changeset_form(high_score, %{name: socket.assigns.name_saved}),
         submit_score_allowed: submit_state
       })}
    else
      socket = assign(socket, game: game)

      if game.state == :ok do
        {:noreply, schedule_end_of_countdown(socket)}
      else
        {:noreply, socket}
      end
    end
  end

  # -------------------- UI EVENTS --------------------

  @impl true
  def handle_event("start", _value, socket) do
    socket =
      start_game(socket)
      |> schedule_end_of_countdown()

    {:noreply, socket}
  end

  @impl true
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

  @impl true
  def handle_event("name_change", %{"high_score" => high_score}, socket) do
    submit_state =
      case String.length(high_score["name"]) > 0 do
        true -> :ok
        false -> :ko
      end

    {:noreply, assign(socket, submit_score_allowed: submit_state)}
  end

  @impl true
  def handle_event("submit_best", %{"high_score" => high_score}, socket) do
    name = Map.get(high_score, "name")
    game = Game.add_best(socket.assigns.game, name)
    Logger.info("Submit high score: (#{socket.assigns.space.codename}) #{name} - #{game.score}")

    {:noreply,
     socket
     |> push_event("update_name", %{name: name})
     |> assign(game: game, name: name, name_saved: name, submit_score: :ok)}
  end

  # -------------------- UI UTILS --------------------

  def is_high_score?(%{score: 0} = _game) do
    false
  end

  def is_high_score?(game) do
    duration = Game.get_duration(game)
    Score.is_high_score?(game.space, game.score, duration)
  end

  def countdown_state(_conn, game) do
    cond do
      Enum.member?([:ok], game.state) == true -> "start"
      true -> "stop"
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

  def game_state_class(_conn, game) do
    if game.state in [:ok, :win, :gameover] do
      "state-" <> Atom.to_string(game.state)
    else
      ""
    end
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
        Store.update_pictures([person.id])
        "error"
    end
  end
end
