defmodule TwitchGameServerWeb.GameSocket do
  @moduledoc """
  The Game server web socket.
  """

  @behaviour Phoenix.Socket.Transport

  require Logger

  alias TwitchGameServer.CommandServer

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
    TwitchGameServer.subscribe("commands")
    schedule_ping()
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_in({text, _opts}, state) do
    result =
      case Jason.decode!(text) do
        %{"set_rate" => rate_ms} ->
          Logger.debug("[GameSocket] setting rate to: #{rate_ms}ms")
          CommandServer.set_rate(rate_ms)
          %{success: true, rate: rate_ms}

        %{"set_queue_limit" => limit} ->
          Logger.debug("[GameSocket] set queue limit: #{limit}")
          CommandServer.set_queue_limit(limit)
          %{success: true}

        %{"set_filters" => %{"commands" => commands, "matches" => matches}} ->
          Logger.debug("[GameSocket] filter: #{inspect(commands)} and #{inspect(matches)}")
          matches = Enum.map(matches, &Regex.compile!/1)
          CommandServer.set_filters(commands: commands, matches: matches)
          %{success: true}

        %{"add_command_filter" => command} ->
          Logger.debug("[GameSocket] add command filter: #{command}")
          CommandServer.add_command_filter(command)
          %{success: true}

        %{"remove_command_filter" => command} ->
          Logger.debug("[GameSocket] remove command filter: #{command}")
          CommandServer.remove_command_filter(command)
          %{success: true}

        %{"add_match_filter" => match} ->
          Logger.debug("[GameSocket] add match filter: #{match}")
          Regex.compile!(match) |> CommandServer.add_match_filter()
          %{success: true}

        %{"remove_match_filter" => match} ->
          Logger.debug("[GameSocket] remove match filter: #{match}")
          Regex.compile!(match) |> CommandServer.remove_match_filter()
          %{success: true}

        %{"flush_user" => username} ->
          Logger.debug("[GameSocket] flush user queue: #{username}")
          CommandServer.flush_user(username)
          %{success: true}

        msg ->
          Logger.warning("[GameSocket] unhandled text frame: #{inspect(msg)}")
          %{success: false, error: "unrecognized"}
      end

    {:reply, :ok, {:text, Jason.encode!(result)}, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_info({:commands, commands}, state) do
    {:push, {:text, Jason.encode!(%{commands: commands})}, state}
  end

  def handle_info(:send_ping, state) do
    Logger.debug("[GameSocket] sending ping...")
    schedule_ping()
    {:push, {:ping, ""}, state}
  end

  def handle_info(msg, state) do
    Logger.warning("[GameSocket] unhandled message: #{inspect(msg)}")
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_control({payload, opts}, state) do
    case opts[:opcode] do
      :pong ->
        Logger.debug("[GameSocket] got pong")
        {:ok, state}

      _opcode ->
        Logger.warning("[GameSocket] unknown control frame: #{inspect({payload, opts})}")
        {:ok, state}
    end
  end

  @impl Phoenix.Socket.Transport
  def terminate(reason, _state) do
    Logger.info("[GameSocket] closing socket: #{inspect(reason)}")
    :ok
  end

  defp schedule_ping do
    Process.send_after(self(), :send_ping, @ping_interval)
  end
end
