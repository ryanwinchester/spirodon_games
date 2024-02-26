defmodule TwitchGameServerWeb.Router do
  use TwitchGameServerWeb, :router

  import TwitchGameServerWeb.Auth.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TwitchGameServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitchGameServerWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/game", GameController, :show

    live "/leaderboard", ScoreLive.Index, :index
    # live "/scores/new", ScoreLive.Index, :new
    # live "/scores/:id/edit", ScoreLive.Index, :edit
    # live "/scores/:id", ScoreLive.Show, :show
    # live "/scores/:id/show/edit", ScoreLive.Show, :edit
  end

  ## Authentication routes

  scope "/auth", TwitchGameServerWeb.Auth do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{TwitchGameServerWeb.Auth.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/register", UserRegistrationLive, :new
      live "/login", UserLoginLive, :new
      live "/reset_password", UserForgotPasswordLive, :new
      live "/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/login", UserSessionController, :create
  end

  scope "/users", TwitchGameServerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{TwitchGameServerWeb.Auth.UserAuth, :ensure_authenticated}] do
      live "/settings", UserSettingsLive, :edit
      live "/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/auth", TwitchGameServerWeb.Auth do
    pipe_through [:browser]

    delete "/logout", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{TwitchGameServerWeb.Auth.UserAuth, :mount_current_user}] do
      live "/confirm/:token", UserConfirmationLive, :edit
      live "/confirm", UserConfirmationInstructionsLive, :new
    end
  end

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
