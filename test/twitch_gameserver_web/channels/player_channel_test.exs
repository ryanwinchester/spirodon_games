defmodule TwitchGameServerWeb.PlayerChannelTest do
  use TwitchGameServerWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      socket(TwitchGameServerWeb.NewGameScoket)
      |> subscribe_and_join(
        TwitchGameServerWeb.PlayerChannel,
        "player:123",
        %{
          id: "123",
          login: "testuser",
          name: "Test User",
          channel: "testuser"
        }
      )

    %{socket: socket}
  end
end
