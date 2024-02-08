defmodule TwitchGameServer.GameFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TwitchGameServer.Game` context.
  """

  @doc """
  Generate a top score.
  """
  def top_score_fixture(attrs \\ %{}) do
    {:ok, top_score} =
      attrs
      |> Enum.into(%{
        score: 42,
        username: "some user"
      })
      |> TwitchGameServer.Game.create_top_score()

    top_score
  end
end
