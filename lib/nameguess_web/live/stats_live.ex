defmodule NameGuessWeb.StatsLive do
  require Logger
  use NameGuessWeb, :live_view
  alias NameGuess.{Score, People, Space, Image}
  alias NameGuess.People.Stats

  @impl true
  def render(assigns) do
    ~H"""
      <div class="grid-x grid-padding-x">
        <div class="cell auto">
          <h4 class="text-center cat-title"><%= gettext "Stats" %> - <%= @space.name %></h4>
        </div>
      </div>

      <div class="grid-x grid-padding-x">
        <div class="cell small-12 medium-5 medium-order-1 small-order-3 space-up-20-sm">
          <form id="stats-divisions" phx-change="division_change">
              <label><%= gettext "Filter by a team:" %>
              <%= select :divisions, :division_id, @divisions, [{:selected, @division_selected}] %>
              </label>
          </form>
        </div>
        <div class="cell small-6 medium-offset-1 medium-3 medium-order-1 small-order-1">
            <p class="text-center"><%= gettext("<strong>%{total} names</strong><br>to guess.", total: @number_of_people) |> raw() %></p>
            <p :if={@duration != nil} class="text-center"><%= gettext("<strong>%{duration}</strong><br>of lost productivity ;)", duration: @duration) |> raw() %></p>
        </div>
        <div class="cell small-6 medium-3 medium-order-3 small-order-2">
            <p class="text-center"><%= gettext("<strong>%{total} games</strong><br> played", total: @number_of_games) |> raw() %></p>
            <p class="text-center"><%= gettext("<strong>%{total} games</strong><br> with a score of 0", total: @number_of_score_0) |> raw() %></p>
        </div>
      </div>

      <div class="grid-x grid-padding-x">
        <div class="cell small-12 medium-6 space-up-25">
          <h5 class="text-center cat-title"><%= gettext "Most recognized people" %></h5>
          <hr class="hr-space">
          <%= if length(@most_guessed) > 0 do %>
            <%= for {person, index} <- Enum.with_index(@most_guessed) do %>
              <div class="media-object media-object-stats">
                <div class="stats-index">#<%= index + 1 %></div>
                <div class="media-object-section">
                  <div class="thumbnail">
                    <img title={Map.fetch!(person, "position")} alt={Map.get(person, "name")} src={Routes.static_path(@socket, thumbnail_path(person))}>
                  </div>
                </div>
                <div class="media-object-section">
                  <h6><%= Map.get(person, "name") %> <span class="stats-percent">(<%= Map.get(person, "percent_guessed") %>%)</span></h6>
                  <p :if={length(Map.get(person, "wrong_names")) > 0}>
                    <%= gettext "Also called" %>: <%=  Enum.join(Map.get(person, "wrong_names"), ", ") %>
                    <%= if length(Map.get(person, "wrong_names")) == 10 do %>...<% end %>
                  </p>
                </div>
              </div>
            <% end %>
          <% else %>
            <div class="no-data"><%= gettext "No data" %></div>
          <% end %>
        </div>

        <div class="cell small-12 medium-6 space-up-25">
          <h5 class="text-center cat-title"><%= gettext "Least recognized people" %></h5>
          <hr class="hr-space">
          <%= if length(@least_guessed) > 0 do %>
            <%= for {person, index} <- Enum.with_index(@least_guessed) do %>
              <div class="media-object media-object-stats text-right" style="width: 100%">
                <div class="media-object-section media-object-content">
                  <h6><%= Map.fetch!(person, "name") %> <span class="stats-percent">(<%= Map.get(person, "percent_guessed") %>%)</span></h6>
                  <p :if={length(Map.get(person, "wrong_names")) > 0}>
                    <%= gettext "Also called" %>: <%=  Enum.join(Map.get(person, "wrong_names"), ", ") %>
                    <%= if length(Map.get(person, "wrong_names")) == 10 do %>...<% end %>
                  </p>
                </div>
                <div class="media-object-section">
                  <div class="thumbnail">
                    <img title={Map.fetch!(person, "position")} alt={Map.fetch!(person, "name")} src={Routes.static_path(@socket, thumbnail_path(person))}>
                  </div>
                </div>
                <div class="stats-index">#<%= index + 1 %></div>
              </div>
            <% end %>
          <% else %>
            <div class="no-data">No data</div>
          <% end %>
        </div>
      </div>

      <div class="grid-x grid-padding-x">
        <div class="cell auto">
          <p class="space-up-50 text-center">
            <a class="button play-game" href={Routes.live_path(@socket, NameGuessWeb.GameLive, @space.codename)}><%= gettext "Play now" %></a>
          </p>
        </div>
      </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    space = session["space"]

    number_of_people = People.get_keys_total(space)
    most_guessed = Stats.get_most_guessed(space)
    least_guessed = Stats.get_least_guessed(space)
    number_of_games = Score.get_number_of_games(space)
    duration = Score.get_space_duration(space)
    number_of_score_0 = Score.count_score(space, 0)

    divisions = People.get_divisions(space)

    divisions =
      unless length(divisions) == 1 do
        [{"All", ""} | People.get_divisions(space)]
      else
        divisions
      end

    socket =
      assign(socket,
        space: space,
        most_guessed: most_guessed,
        least_guessed: least_guessed,
        number_of_games: number_of_games,
        duration: duration,
        number_of_people: number_of_people,
        number_of_score_0: number_of_score_0,
        divisions: divisions,
        division_selected: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"division_key" => division_key}, _uri, socket) do
    division_name = get_division_full(socket.assigns.space, division_key)
    most_guessed = Stats.get_most_guessed(socket.assigns.space, division_name)
    least_guessed = Stats.get_least_guessed(socket.assigns.space, division_name)

    socket =
      assign(socket,
        most_guessed: most_guessed,
        least_guessed: least_guessed,
        division_selected: division_key
      )

    {:noreply, socket}
  end

  @impl true
  def handle_params(_, _uri, socket) do
    most_guessed = Stats.get_most_guessed(socket.assigns.space)
    least_guessed = Stats.get_least_guessed(socket.assigns.space)

    socket =
      assign(socket,
        most_guessed: most_guessed,
        least_guessed: least_guessed,
        division_selected: ""
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("division_change", %{"divisions" => division_choice} = _division, socket) do
    division_key = Map.get(division_choice, "division_id")

    {:noreply,
     push_patch(
       socket,
       to:
         Routes.live_path(
           socket,
           NameGuessWeb.StatsLive,
           socket.assigns.space.codename,
           division_key
         )
     )}
  end

  @spec get_division_full(Space, String.t()) :: String.t()
  defp get_division_full(space, division_key) do
    divisions = People.get_divisions(space)
    {name, _key} = Enum.find(divisions, fn {_name, key} -> key == division_key end)
    name
  end

  defp thumbnail_path(person) do
    "/pics/people_thumbnail/" <> Image.get_picture_filename(person) <> ".jpg"
  end
end
