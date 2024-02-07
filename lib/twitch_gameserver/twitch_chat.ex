defmodule TwitchGameServer.TwitchChat do
  use TwitchChat.Bot

  alias TwitchChat.Events.Message
  alias TwitchGameServer.CommandServer

  @cmd_chain_limit 20

  @impl TwitchChat.Bot
  def handle_event(%Message{message: "!" <> cmd} = msg) do
    cmd
    |> decode()
    |> CommandServer.add(msg)
  end

  # ----------------------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------------------

  defp decode("up"), do: [:up]
  defp decode("down"), do: [:down]
  defp decode("left"), do: [:left]
  defp decode("right"), do: [:right]
  defp decode(cmd) when byte_size(cmd) > @cmd_chain_limit, do: []
  defp decode(cmd), do: decode(cmd, [])

  defp decode("", acc), do: Enum.reverse(acc)
  defp decode("u" <> rest, acc), do: decode(rest, [:up | acc])
  defp decode("d" <> rest, acc), do: decode(rest, [:down | acc])
  defp decode("l" <> rest, acc), do: decode(rest, [:left | acc])
  defp decode("r" <> rest, acc), do: decode(rest, [:right | acc])
  defp decode(<<_::8, rest::binary>>, acc), do: decode(rest, acc)
end
