defmodule TwitchGameServerWeb.GameController do
  use TwitchGameServerWeb, :controller
  plug :put_root_layout, false
  plug :put_layout, false

  def index(conn, _params) do
    render(conn, :index)
  end
end
