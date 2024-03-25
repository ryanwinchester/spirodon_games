defmodule TwitchGameServerWeb.PlayerChannel do
  use TwitchGameServerWeb, :channel

  alias TwitchGameServer.CommandServer
  alias TwitchGameServer.Game.Player

  require Logger

  @impl true
  def join(
        "player:" <> _player_id,
        %{"id" => id, "login" => login, "name" => name, "channel" => channel} = payload,
        socket
      ) do
    if authorized?(payload) do
      TwitchGameServer.subscribe("messages")
      TwitchGameServer.subscribe("messages:{#login}")

      player = %Player{
        id: id,
        login: login,
        name: name,
        channel: channel
      }

      {:ok, assign(socket, :player, player)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("cmd", command, socket) do
    player = socket.assigns.player
    Logger.debug("[PlayerChannel] <#{player.name}> #{command}")

    CommandServer.add(command, %{
      display_name: player.name,
      user_login: player.login,
      channel: player.channel,
      timestamp: DateTime.utc_now()
    })

    {:reply, {:ok, %{cmd: command}}, socket}
  end

  @impl true
  def handle_info({:server, msg}, socket) do
    Logger.debug("[PlayerChannel] sending message...")
    push(socket, msg, socket)
  end

  @impl true
  def handle_info(msg, socket) do
    Logger.warning("[PlayerChannel] unhandled message: #{inspect(msg)}")
    {:ok, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
