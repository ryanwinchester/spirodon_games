defmodule TwitchGameServer.TwitchEvents do
  use TwitchEventSub

  @impl true
  def handle_event("channel.channel_points_custom_reward_redemption.add", %{"reward" => %{"title" => "Kraken"}} = event) do
    TwitchGameServer.broadcast("events", {:kraken_redeemed, event})
  end
end
