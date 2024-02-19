defmodule TwitchGameServerWeb.PlayerSocket do
  @moduledoc """
  The Game server web socket.
  """

  @behaviour Phoenix.Socket.Transport

  alias TwitchGameServer.CommandServer

  require Logger

  @ping_interval 30_000

  @impl Phoenix.Socket.Transport
  def child_spec(_opts) do
    # We won't spawn any process, so let's ignore the child spec.
    :ignore
  end

  @impl Phoenix.Socket.Transport
  def connect(state) do
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def init(state) do
    schedule_ping()
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_in({text, _opts}, state) do
    resp =
      case Jason.decode!(text) do
        %{"command" => cmd, "user" => user, "ts" => timestamp} = msg ->
          %{"display_name" => display_name, "user_login" => login, "channel" => channel} = user
          Logger.debug("[PlayerSocket] <#{display_name}> #{cmd}")

          CommandServer.add(cmd, %{
            display_name: display_name,
            user_login: login,
            channel: channel,
            timestamp: DateTime.from_unix!(timestamp, :second)
          })

          msg

        unrecognized ->
          Logger.warning("[PlayerSocket] unhandled text frame: #{inspect(unrecognized)}")
          %{error: "unrecognized"}
      end

    {:reply, :ok, {:text, Jason.encode!(resp)}, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_info(:send_ping, state) do
    Logger.debug("[PlayerSocket] sending ping...")
    schedule_ping()
    {:push, {:ping, ""}, state}
  end

  def handle_info(msg, state) do
    Logger.warning("[PlayerSocket] unhandled message: #{inspect(msg)}")
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_control({payload, opts}, state) do
    case opts[:opcode] do
      :pong ->
        Logger.debug("[PlayerSocket] got pong")
        {:ok, state}

      _opcode ->
        Logger.warning("[PlayerSocket] unknown control frame: #{inspect({payload, opts})}")
        {:ok, state}
    end
  end

  @impl Phoenix.Socket.Transport
  def terminate(reason, _state) do
    Logger.info("[PlayerSocket] closing socket: #{inspect(reason)}")
    :ok
  end

  # ----------------------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------------------

  defp schedule_ping do
    Process.send_after(self(), :send_ping, @ping_interval)
  end
end
