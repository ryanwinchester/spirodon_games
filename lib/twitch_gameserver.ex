defmodule TwitchGameServer do
  @moduledoc """
  TwitchGameServer is really just for Spiro's game.
  """

  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(TwitchGameServer.PubSub, topic, message)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(TwitchGameServer.PubSub, topic)
  end
end
