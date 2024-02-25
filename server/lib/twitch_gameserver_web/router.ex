defmodule TwitchGameServerWeb.Router do
  use TwitchGameServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TwitchGameServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitchGameServerWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/leaderboard", ScoreLive.Index, :index
    # live "/scores/new", ScoreLive.Index, :new
    # live "/scores/:id/edit", ScoreLive.Index, :edit
    # live "/scores/:id", ScoreLive.Show, :show
    # live "/scores/:id/show/edit", ScoreLive.Show, :edit

    resources "/games", GameController
  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitchGameServerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:twitch_gameserver, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TwitchGameServerWeb.Telemetry
    end
  end
end
