defmodule TwitchGameServerWeb.GameSocket do
  @moduledoc """
  The Game server web socket.
  """

  @behaviour Phoenix.Socket.Transport

  require Logger

  alias TwitchGameServer.CommandServer

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
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_in({text, _opts}, state) do
    case Jason.decode!(text) do
      %{"set_rate" => rate_ms} ->
        Logger.debug("[GameSocket] setting rate to: #{rate_ms}ms")
        CommandServer.set_rate(rate_ms)
        {:reply, :ok, {:text, Jason.encode!(%{success: true, rate: rate_ms})}, state}

      %{"set_filters" => %{"commands" => commands, "matches" => matches}} ->
        Logger.debug("[GameSocket] filter: #{inspect(commands)} and #{inspect(matches)}")
        CommandServer.set_filters(commands: commands, matches: matches)
        {:reply, :ok, {:text, Jason.encode!(%{success: true})}, state}

      %{"add_command_filter" => command} ->
        Logger.debug("[GameSocket] add command filter: #{command}")
        CommandServer.add_command_filter(command)
        {:reply, :ok, {:text, Jason.encode!(%{success: true})}, state}

      %{"remove_command_filter" => command} ->
        Logger.debug("[GameSocket] remove command filter: #{command}")
        CommandServer.remove_command_filter(command)
        {:reply, :ok, {:text, Jason.encode!(%{success: true})}, state}

      %{"add_match_filter" => match} ->
        Logger.debug("[GameSocket] add match filter: #{match}")
        CommandServer.add_match_filter(match)
        {:reply, :ok, {:text, Jason.encode!(%{success: true})}, state}

      %{"remove_match_filter" => match} ->
        Logger.debug("[GameSocket] remove match filter: #{match}")
        CommandServer.remove_match_filter(match)
        {:reply, :ok, {:text, Jason.encode!(%{success: true})}, state}

      %{"flush_user" => username} ->
        Logger.debug("[GameSocket] flush user queue: #{username}")
        CommandServer.flush_user(username)
        {:reply, :ok, {:text, Jason.encode!(%{success: true})}, state}

      msg ->
        Logger.warning("[GameSocket] unhandled text frame: #{inspect(msg)}")
        {:reply, :ok, {:text, Jason.encode!(%{success: false, error: "unrecognized"})}, state}
    end
  end

  @impl Phoenix.Socket.Transport
  def handle_info({:commands, commands}, state) do
    {:push, {:text, Jason.encode!(%{commands: commands})}, state}
  end

  def handle_info(msg, state) do
    Logger.warning("[GameSocket] unhandled message: #{inspect(msg)}")
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_control(tuple, state) do
    Logger.debug("[GameSocket] control frame: #{inspect(tuple)}")
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def terminate(reason, _state) do
    Logger.info("[GameSocket] closing socket: #{inspect(reason)}")
    :ok
  end
end
