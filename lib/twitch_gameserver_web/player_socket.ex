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
  def init(%{params: %{"channel" => channel, "id" => id, "login" => login, "name" => name}}) do
    TwitchGameServer.subscribe("messages")
    TwitchGameServer.subscribe("messages:#{login}")
    schedule_ping()

    state = %{
      user: %{id: id, login: login, name: name},
      channel: channel
    }

    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_in({text, _opts}, state) do
    {results, errors, new_state} =
      case Jason.decode!(text) do
        %{"cmd" => cmd, "ts" => ts} ->
          Logger.debug("[PlayerSocket] <#{state.user.name}> #{cmd}")

          CommandServer.add(cmd, %{
            display_name: state.user.name,
            user_login: state.user.login,
            channel: state.channel,
            timestamp: DateTime.from_unix!(ts, :second)
          })

          {%{"cmd" => cmd}, [], state}

        unrecognized ->
          Logger.warning("[PlayerSocket] unhandled text frame: #{inspect(unrecognized)}")
          {nil, ["unrecognized text frame"], state}
      end

    resp = Jason.encode!(%{data: results, errors: errors})

    {:reply, :ok, {:text, resp}, new_state}
  end

  @impl Phoenix.Socket.Transport
  def handle_info(:send_ping, state) do
    Logger.debug("[PlayerSocket] sending ping...")
    schedule_ping()
    {:push, {:ping, ""}, state}
  end

  def handle_info({:server, msg}, state) do
    Logger.debug("[PlayerSocket] sending message...")
    {:push, {:text, Jason.encode!(msg)}, state}
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
