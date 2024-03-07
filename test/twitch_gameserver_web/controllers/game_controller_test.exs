defmodule TwitchGameServerWeb.GameControllerTest do
  use TwitchGameServerWeb.ConnCase

  describe "index" do
    setup [:register_and_login_user]

    test "game page", %{conn: conn} do
      conn = get(conn, ~p"/game")
      assert html_response(conn, 200) =~ ""
    end
  end
end
