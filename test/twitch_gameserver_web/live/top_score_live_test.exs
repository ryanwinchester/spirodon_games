defmodule TwitchGameServerWeb.TopScoreLiveTest do
  use TwitchGameServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import TwitchGameServer.GameFixtures

  defp create_score(_) do
    score = score_fixture()
    %{score: score}
  end

  describe "Index" do
    setup [:create_score, :register_and_login_user]

    test "lists scores", %{conn: conn, score: score} do
      {:ok, _index_live, html} = live(conn, ~p"/leaderboard")

      assert html =~ "Leaderboard"
      assert html =~ score.username
    end
  end
end
