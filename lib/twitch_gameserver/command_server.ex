defmodule TwitchGameServer.CommandServer do
  @moduledoc """
  Orchestrates the user command queues, and sends the messages?
  """
  use GenServer

  alias TwitchGameServer.CommandQueue

  @default_cmd_rate 1000

  @doc """
  Foo does the bar
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add(cmd, msg) do
    GenServer.cast(__MODULE__, {:add, cmd, msg})
  end

  def set_rate(rate_ms) do
    GenServer.cast(__MODULE__, {:set_rate, rate_ms})
  end

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
    # send_and_schedule_next(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:set_rate, rate_ms}, state) do
    {:noreply, %{state | rate: rate_ms}}
  end

  @impl GenServer
  def handle_cast({:add, cmd, msg}, state) do
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
  def handle_call(:slice, _from, state) do
    out =
      state.queues
      |> Enum.map(fn {user, pid} ->
        Task.async(fn -> {user, CommandQueue.out(pid)} end)
      end)
      |> Task.await_many()
      |> Map.new()

    {:reply, out, state}
  end

  # defp send_and_schedule_next(%{queue: queues, rate: rate}) do
  #   {next, queues} =
  #     Enum.reduce(queues, {[], %{}}, fn {user, queue}, {items, queues} ->
  #       case :queue.out(queue) do
  #         {:empty, _queue} ->
  #           {items, queues}

  #         {{:value, {cmd, ts}}, queue} ->
  #           {[{user, cmd, ts} | items], Map.put(queues, user, queue)}
  #       end
  #     end)

  #   Process.send_after(self(), :send, rate)
  # end
end
