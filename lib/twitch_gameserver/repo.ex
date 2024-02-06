defmodule TwitchGameServer.Repo do
  use Ecto.Repo,
    otp_app: :twitch_gameserver,
    adapter: Ecto.Adapters.SQLite3
end
