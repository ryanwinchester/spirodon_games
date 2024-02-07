defmodule TwitchGameServer.CommandQueue do
  @moduledoc """
  The per-user command queue.
  """
  use GenServer

  @type message :: TwitchChat.Events.Message.t()

  @type role :: :broadcaster | :mod | :sub | :normal

  @doc """
  Start the CommandQueue GenServer.
  """
  @spec start_link(term()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Child spec, duh.
  """
  @spec child_spec(term()) :: Supervisor.child_spec()
  def child_spec(id) do
    %{
      id: id,
      start: {__MODULE__, :start_link, [[]]}
    }
  end

  @doc """
  Add a command to the queue.
  """
  @spec add(pid(), String.t(), message(), pos_integer()) :: :ok
  def add(pid, cmd, msg, limit) do
    GenServer.cast(pid, {:add, cmd, msg, limit})
  end

  @doc """
  Get the next command from the queue.
  """
  @spec out(pid()) :: {user :: String.t(), unix_time :: integer(), role :: String.t()}
  def out(pid) do
    GenServer.call(pid, :out)
  end

  # ----------------------------------------------------------------------------
  # GenServer callbacks
  # ----------------------------------------------------------------------------

  @impl GenServer
  def init(_opts) do
    {:ok, :queue.new()}
  end

  @impl GenServer
  def handle_cast({:add, cmd, msg, limit}, queue) do
    if :queue.len(queue) < limit do
      timestamp = DateTime.to_unix(msg.timestamp, :millisecond)
      role = role_from_message(msg)
      {:noreply, :queue.in({cmd, timestamp, role}, queue)}
    else
      {:noreply, queue}
    end
  end

  @impl GenServer
  def handle_call(:out, _from, queue) do
    case :queue.out(queue) do
      {:empty, queue} -> {:reply, nil, queue}
      {{:value, item}, queue} -> {:reply, item, queue}
    end
  end

  # ----------------------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------------------

  # Get the role from the message.
  # Note: If we switch to EventSub, this will need to change.
  defp role_from_message(%{user_login: user, channel: user}), do: :broadcaster
  defp role_from_message(%{is_mod?: true}), do: :mod
  defp role_from_message(%{is_vip?: true}), do: :vip
  defp role_from_message(%{is_sub?: true}), do: :sub
  defp role_from_message(_msg), do: :normal
end
