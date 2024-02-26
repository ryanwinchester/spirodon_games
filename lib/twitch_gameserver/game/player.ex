defmodule TwitchGameServer.Game.Player do
  @enforce_keys [:id, :name, :login, :channel]
  defstruct [:id, :name, :login, :channel]
end
