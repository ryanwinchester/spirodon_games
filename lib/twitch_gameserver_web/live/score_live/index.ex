defmodule TwitchGameServerWeb.ScoreLive.Index do
  use TwitchGameServerWeb, :live_view

  alias TwitchGameServer.Game

  @default_count 20

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      TwitchGameServer.subscribe("scores")
    end

    socket =
      socket
      |> assign(:page_title, "Leaderboard")
      |> assign(:filter_form, to_form(%{"user" => nil}))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    top =
      if count = params["count"], do: String.to_integer(count), else: @default_count

    socket =
      socket
      |> assign(:count, top)
      |> assign(:scores, Game.leaderboard(top: top))

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", %{"user" => search} = params, socket) do
    scores = Game.leaderboard(top: socket.assigns.count, filters: [username: search])

    socket =
      socket
      |> assign(:filter_form, to_form(params))
      |> assign(:scores, scores)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:score_updated, _score_id}, socket) do
    {:noreply, assign(socket, :scores, Game.leaderboard(top: socket.assigns.count))}
  end
end
