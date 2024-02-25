defmodule TwitchGameServer.GameFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TwitchGameServer.Game` context.
  """

  @doc """
  Generate a top score.
  """
  def score_fixture(attrs \\ %{}) do
    {:ok, score} =
      attrs
      |> Enum.into(%{
        total: 42,
        username: "some user"
      })
      |> TwitchGameServer.Game.create_score()

    score
  end
end
