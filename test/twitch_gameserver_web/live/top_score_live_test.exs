defmodule TwitchGameServerWeb.TopScoreLiveTest do
  use TwitchGameServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import TwitchGameServer.GameFixtures

  defp create_score(_) do
    top_score = top_score_fixture()
    %{top_score: top_score}
  end

  describe "Index" do
    setup [:create_score]

    test "lists top scores", %{conn: conn, top_score: top_score} do
      {:ok, _index_live, html} = live(conn, ~p"/leaderboard")

      assert html =~ "Leaderboard"
      assert html =~ top_score.username
    end
  end
end
