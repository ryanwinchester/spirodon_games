defmodule TwitchGameServerWeb.GameHTML do
  use TwitchGameServerWeb, :html

  embed_templates "game_html/*"

  defp user_to_raw_json(user) do
    user
    |> Jason.encode!()
    |> inspect()
    |> raw()
  end
end
