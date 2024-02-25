defmodule TwitchGameServerWeb.GameControllerTest do
  use TwitchGameServerWeb.ConnCase

  describe "index" do
    test "lists all games", %{conn: conn} do
      conn = get(conn, ~p"/games")
      assert html_response(conn, 200) =~ ""
    end
  end
end
