defmodule TwitchGameServerWeb.GameController do
  use TwitchGameServerWeb, :controller

  plug :put_root_layout, false
  plug :put_layout, false

  def show(conn, _params) do
    render(conn, :show)
  end
end
