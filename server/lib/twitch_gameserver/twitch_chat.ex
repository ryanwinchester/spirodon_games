defmodule TwitchGameServer.TwitchChat do
  @moduledoc """
  Twitch chat event handler.
  """
  use TwitchChat.Bot

  alias TwitchChat.Events.Message
  alias TwitchGameServer.CommandServer

  @impl TwitchChat.Bot
  def handle_event(%Message{message: "!" <> cmd} = msg) do
    CommandServer.add(cmd, msg)
  end
end
