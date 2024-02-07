defmodule TwitchGameServer.TwitchChat do
  @moduledoc """
  Twitch chat event handler.
  """
  use TwitchChat.Bot

  require Logger

  alias TwitchChat.Events.Message
  alias TwitchGameServer.CommandServer

  @impl TwitchChat.Bot
  def handle_event(%Message{message: "!" <> cmd} = msg) do
    Logger.info(inspect(msg))
    CommandServer.add(cmd, msg)
  end

  def handle_event(%Message{} = msg) do
    Logger.info(inspect(Map.take(msg, [:badges, :user_type, :is_sub?, :is_mod?, :is_vip?, :user_login])))
  end
end
