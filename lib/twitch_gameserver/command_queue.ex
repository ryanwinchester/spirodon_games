defmodule TwitchGameServer.CommandQueue do
  @moduledoc """
  The per-user command queue.
  """
  use GenServer

  alias TwitchGameServer.Accounts.ChannelRole

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
      roles = Enum.reduce(ChannelRole.roles(), [], &add_role(&1, &2, msg))
      {:noreply, :queue.in({cmd, timestamp, roles}, queue)}
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

  defp add_role(:broadcaster, %{user_login: user, channel: user}, roles),
    do: [:broadcaster | roles]

  defp add_role(:mod, %{is_mod?: true}, roles), do: [:mod | roles]
  defp add_role(:vip, %{is_vip?: true}, roles), do: [:vip | roles]
  defp add_role(:sub, %{is_sub?: true}, roles), do: [:sub | roles]
  defp add_role(_role, _msg, roles), do: roles
end
