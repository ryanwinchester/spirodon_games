defmodule TwitchGameServerWeb.GameChannel do
  use TwitchGameServerWeb, :channel

  require Logger

  alias TwitchGameServer.Game
  alias TwitchGameServer.CommandServer

  @impl true
  def join("game:" <> _game_id, payload, socket) do
    if authorized?(payload) do
      TwitchGameServer.subscribe("commands")
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("run-commands", payload, socket) do
    {results, errors} =
      Enum.reduce(payload, {_results = %{}, _errors = []}, &handle_data/2)

    response = %{data: results, errors: errors}

    {:reply, {:ok, response}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp map_errors(errors) do
    Map.new(errors, fn {field, {message, _}} ->
      {field, message}
    end)
  end

  defp handle_data({"set_rate", rate_ms}, {results, errors}) do
    Logger.debug("[GameChannel] setting rate to: #{rate_ms}ms")
    CommandServer.set_rate(rate_ms)
    results = Map.put(results, :rate, rate_ms)
    {results, errors}
  end

  defp handle_data({"set_queue_limit", limit}, {results, errors}) do
    Logger.debug("[GameChannel] set queue limit: #{limit}")
    CommandServer.set_queue_limit(limit)
    results = Map.put(results, :queue_limit, limit)
    {results, errors}
  end

  defp handle_data(
         {"set_filters", %{"commands" => commands, "matches" => matches}},
         {results, errors}
       ) do
    Logger.debug("[GameChannel] filter: #{inspect(commands)} and #{inspect(matches)}")
    matches = Enum.map(matches, &Regex.compile!/1)
    CommandServer.set_filters(commands: commands, matches: matches)
    results = Map.put(results, :filters, parse_filters(%{commands: commands, matches: matches}))
    {results, errors}
  end

  defp handle_data({"add_command_filter", command}, {results, errors}) do
    Logger.debug("[GameChannel] add command filter: #{command}")
    CommandServer.add_command_filter(command)
    results = Map.put(results, :filters, CommandServer.get_filters() |> parse_filters())
    {results, errors}
  end

  defp handle_data({"remove_command_filter", command}, {results, errors}) do
    Logger.debug("[GameChannel] remove command filter: #{command}")
    CommandServer.remove_command_filter(command)
    results = Map.put(results, :filters, CommandServer.get_filters() |> parse_filters())
    {results, errors}
  end

  defp handle_data({"add_match_filter", match}, {results, errors}) do
    Logger.debug("[GameChannel] add match filter: #{match}")
    Regex.compile!(match) |> CommandServer.add_match_filter()
    results = Map.put(results, :filters, CommandServer.get_filters() |> parse_filters())
    {results, errors}
  end

  defp handle_data({"remove_match_filter", match}, {results, errors}) do
    Logger.debug("[GameChannel] remove match filter: #{match}")
    Regex.compile!(match) |> CommandServer.remove_match_filter()
    results = Map.put(results, :filters, CommandServer.get_filters() |> parse_filters())
    {results, errors}
  end

  defp handle_data({"flush_user", username}, {results, errors}) do
    Logger.debug("[GameChannel] flush user queue: #{username}")
    CommandServer.flush_user(username)
    {results, errors}
  end

  defp handle_data({"get_leaderboard", count}, {results, errors}) do
    Logger.debug("[GameChannel] getting leaderboard")

    leaderboard =
      Game.leaderboard(top: count)
      |> Enum.map(fn {rank, username, score} ->
        %{rank: rank, user: username, total: score}
      end)

    {Map.put(results, :leaderboard, leaderboard), errors}
  end

  defp handle_data({"increment_score", %{"user" => username, "inc" => inc}}, {results, errors}) do
    Logger.debug("[GameChannel] incrementing score for: #{username}")

    case Game.increment_score_by_username(username, inc) do
      {:ok, score} ->
        result = %{user: score.username, total: score.total}
        {Map.put(results, :score, result), errors}

      {:error, changeset} ->
        error = %{increment_score: map_errors(changeset.errors)}
        {results, [error | errors]}
    end
  end

  defp handle_data({"broadcast", %{"payload" => payload}}, {results, errors}) do
    Logger.debug("[GameChannel] broadcasting message to all users")
    TwitchGameServer.broadcast("messages", {:server, payload})
    {results, errors}
  end

  defp handle_data({"send", %{"user" => username, "payload" => payload}}, {results, errors}) do
    Logger.debug("[GameChannel] sending message to user: #{username}")
    # TODO: Switch this to use broadcast_from!
    TwitchGameServer.broadcast("messages:#{username}", {:server, payload})
    {results, errors}
  end

  defp handle_data(msg, {results, errors}) do
    Logger.warning("[GameChannel] unhandled text frame: #{inspect(msg)}")
    error = %{unrecognized: inspect(msg)}
    {results, [error | errors]}
  end

  # Regex can't be turned into JSON, so we need to handle that for the `:matches`.
  defp parse_filters(filters) do
    Map.update(filters, :matches, [], &Enum.map(&1, fn regex -> Regex.source(regex) end))
  end
end
