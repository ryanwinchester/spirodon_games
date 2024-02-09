defmodule TwitchGameServerWeb.GameSocket do
  @moduledoc """
  The Game server web socket.
  """

  @behaviour Phoenix.Socket.Transport

  require Logger

  alias TwitchGameServer.CommandServer
  alias TwitchGameServer.Game

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
    {results, errors} =
      text
      |> Jason.decode!()
      |> Enum.reduce({_results = %{}, _errors = []}, &handle_data/2)

    result = Jason.encode!(%{data: results, errors: errors})

    {:reply, :ok, {:text, result}, state}
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

  # ----------------------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------------------

  defp schedule_ping do
    Process.send_after(self(), :send_ping, @ping_interval)
  end

  defp map_errors(errors) do
    Map.new(errors, fn {field, {message, _}} ->
      {field, message}
    end)
  end

  defp handle_data({"set_rate", rate_ms}, results) do
    Logger.debug("[GameSocket] setting rate to: #{rate_ms}ms")
    CommandServer.set_rate(rate_ms)
    results
  end

  defp handle_data({"set_queue_limit", limit}, results) do
    Logger.debug("[GameSocket] set queue limit: #{limit}")
    CommandServer.set_queue_limit(limit)
    results
  end

  defp handle_data({"set_filters", %{"commands" => commands, "matches" => matches}}, results) do
    Logger.debug("[GameSocket] filter: #{inspect(commands)} and #{inspect(matches)}")
    matches = Enum.map(matches, &Regex.compile!/1)
    CommandServer.set_filters(commands: commands, matches: matches)
    results
  end

  defp handle_data({"add_command_filter", command}, results) do
    Logger.debug("[GameSocket] add command filter: #{command}")
    CommandServer.add_command_filter(command)
    results
  end

  defp handle_data({"remove_command_filter", command}, results) do
    Logger.debug("[GameSocket] remove command filter: #{command}")
    CommandServer.remove_command_filter(command)
    results
  end

  defp handle_data({"add_match_filter", match}, results) do
    Logger.debug("[GameSocket] add match filter: #{match}")
    Regex.compile!(match) |> CommandServer.add_match_filter()
    results
  end

  defp handle_data({"remove_match_filter", match}, results) do
    Logger.debug("[GameSocket] remove match filter: #{match}")
    Regex.compile!(match) |> CommandServer.remove_match_filter()
    results
  end

  defp handle_data({"flush_user", username}, results) do
    Logger.debug("[GameSocket] flush user queue: #{username}")
    CommandServer.flush_user(username)
    results
  end

  defp handle_data({"get_leaderboard", count}, {results, errors}) do
    Logger.debug("[GameSocket] getting leaderboard")

    leaderboard =
      Game.leaderboard(top: count)
      |> Enum.map(fn {rank, username, score} ->
        %{rank: rank, user: username, total: score}
      end)

    {Map.put(results, "leaderboard", leaderboard), errors}
  end

  defp handle_data({"increment_score", %{"user" => username, "inc" => inc}}, {results, errors}) do
    Logger.debug("[GameSocket] incrementing score for: #{username}")

    case Game.increment_score_by_username(username, inc) do
      {:ok, score} ->
        result = %{"user" => score.username, "total" => score.total}
        {Map.put(results, "score", result), errors}

      {:error, changeset} ->
        error = %{"increment_score" => map_errors(changeset.errors)}
        {results, [error | errors]}
    end
  end

  defp handle_data(msg, {results, errors}) do
    Logger.warning("[GameSocket] unhandled text frame: #{inspect(msg)}")
    error = %{"unrecognized" => inspect(msg)}
    {results, [error | errors]}
  end
end
