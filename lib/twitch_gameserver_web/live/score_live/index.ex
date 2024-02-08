defmodule TwitchGameServerWeb.ScoreLive.Index do
  use TwitchGameServerWeb, :live_view

  alias TwitchGameServer.Game

  @default_count 20

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      TwitchGameServer.subscribe("top_scores")
    end

    {:ok, assign(socket, :page_title, "Listing Scores")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    top =
      if count = params["count"], do: String.to_integer(count), else: @default_count

    socket =
      socket
      |> assign(:count, top)
      |> assign(:scores, Game.leaderboard(top))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:top_score_added, _score_id}, socket) do
    {:noreply, assign(socket, :scores, Game.leaderboard(socket.assigns.count))}
  end
end
