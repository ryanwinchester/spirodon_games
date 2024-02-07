defmodule TwitchGameServer.CommandServer do
  @moduledoc """
  Orchestrates the user command queues, and sends the messages?
  """
  use GenServer

  alias TwitchGameServer.CommandQueue

  @default_cmd_rate 1000

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

  def handle_cast({:set_filters, _filters}, state) do
    # TODO: set filters `:commands` and `:matches`.
    {:noreply, state}
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
    # TODO: filter on allowed commands and matches.
    queues =
      Map.put_new_lazy(state.queues, msg.user_name, fn ->
        child_spec = CommandQueue.child_spec(msg.user_name)
        {:ok, pid} = DynamicSupervisor.start_child(TwitchGameServer.DynamicSupervisor, child_spec)
        pid
      end)

    queues
    |> Map.fetch!(msg.user_name)
    |> CommandQueue.add(cmd, msg)

    {:noreply, %{state | queues: queues}}
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
        with {cmd, timestamp} <- CommandQueue.out(pid) do
          %{user: user, command: cmd, timestamp: timestamp}
        end
      end)
    end)
    |> Task.await_many()
    |> Enum.reject(&is_nil/1)
  end

  defp schedule_next(%{rate: rate}) do
    Process.send_after(self(), :slice, rate)
  end
end
