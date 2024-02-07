defmodule TwitchGameServer.CommandServer do
  @moduledoc """
  Orchestrates the user command queues, and sends the messages?
  """
  use GenServer

  alias TwitchGameServer.CommandQueue

  @default_cmd_rate 1000
  @default_queue_limit 20

  @doc """
  Starts the command server for orchestrating user command queues.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add(cmd, msg) do
    GenServer.cast(__MODULE__, {:add, cmd, msg})
  end

  def flush_user(username) do
    GenServer.cast(__MODULE__, {:flush_user, username})
  end

  def set_rate(rate_ms) do
    GenServer.cast(__MODULE__, {:set_rate, rate_ms})
  end

  def set_queue_limit(limit) do
    GenServer.cast(__MODULE__, {:set_queue_limit, limit})
  end

  def set_filters(filters) do
    GenServer.cast(__MODULE__, {:set_filters, filters})
  end

  def add_command_filter(command_filter) do
    GenServer.cast(__MODULE__, {:add_command_filter, command_filter})
  end

  def remove_command_filter(command_filter) do
    GenServer.cast(__MODULE__, {:remove_command_filter, command_filter})
  end

  def add_match_filter(match_filter) do
    GenServer.cast(__MODULE__, {:add_match_filter, match_filter})
  end

  def remove_match_filter(match_filter) do
    GenServer.cast(__MODULE__, {:remove_match_filter, match_filter})
  end

  # ----------------------------------------------------------------------------
  # GenServer callbacks
  # ----------------------------------------------------------------------------

  @impl GenServer
  def init(opts) do
    state = %{
      filters: %{commands: [], matches: []},
      queue_limit: Keyword.get(opts, :queue_limit, @default_queue_limit),
      rate: Keyword.get(opts, :rate, @default_cmd_rate),
      queues: %{}
    }

    {:ok, state, {:continue, :schedule}}
  end

  @impl GenServer
  def handle_continue(:schedule, state) do
    schedule_next(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:set_rate, rate_ms}, state) do
    {:noreply, %{state | rate: rate_ms}}
  end

  def handle_cast({:set_queue_limit, limit}, state) do
    {:noreply, %{state | queue_limit: limit}}
  end

  def handle_cast({:set_filters, filters}, state) do
    {:noreply, %{state | filters: filters}}
  end

  def handle_cast({:add_command_filter, filter}, state) do
    {:noreply, update_in(state, [:filters, :commands], &[filter | &1])}
  end

  def handle_cast({:remove_command_filter, filter}, state) do
    {:noreply, update_in(state, [:filters, :commands], &List.delete(&1, filter))}
  end

  def handle_cast({:add_match_filter, filter}, state) do
    {:noreply, update_in(state, [:filters, :matches], &[filter | &1])}
  end

  def handle_cast({:remove_match_filter, filter}, state) do
    {:noreply, update_in(state, [:filters, :matches], &List.delete(&1, filter))}
  end

  def handle_cast({:flush_user, username}, state) do
    case Map.get(state.queues, username) do
      nil -> :ignore
      pid -> GenServer.stop(pid)
    end

    queues = Map.delete(state.queues, username)

    {:noreply, %{state | queues: queues}}
  end

  @impl GenServer
  def handle_cast({:add, cmd, msg}, state) do
    if enqueue_command?(cmd, state) do
      queues =
        Map.put_new_lazy(state.queues, msg.user_name, fn ->
          start_queue(msg.user_name)
        end)

      Task.start(fn ->
        queues
        |> Map.fetch!(msg.user_name)
        |> CommandQueue.add(cmd, msg, state.queue_limit)
      end)

      {:noreply, %{state | queues: queues}}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(:slice, state) do
    case get_command_slice(state.queues) do
      [] -> :ok
      commands -> TwitchGameServer.broadcast("commands", {:commands, commands})
    end

    schedule_next(state)

    {:noreply, state}
  end

  # ----------------------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------------------

  # Get the next command for every user that has commands left in their queue.
  defp get_command_slice(queues) do
    queues
    |> Enum.map(fn {user, pid} ->
      Task.async(fn ->
        with {cmd, timestamp, role} <- CommandQueue.out(pid) do
          %{cmd: cmd, ts: timestamp, user: user, role: role}
        end
      end)
    end)
    |> Task.await_many()
    |> Enum.reject(&is_nil/1)
  end

  defp enqueue_command?(cmd, state) do
    # TODO: Limit the user's queue size by the `state.queue_limit`.

    Enum.any?(state.filters.commands, &match?(^&1 <> _, cmd)) or
      Enum.any?(state.filters.matches, &Regex.match?(&1, cmd))
  end

  defp start_queue(user) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        TwitchGameServer.DynamicSupervisor,
        CommandQueue.child_spec(user)
      )

    pid
  end

  defp schedule_next(%{rate: rate}) do
    Process.send_after(self(), :slice, rate)
  end
end
