defmodule TwitchGameServerWeb.Auth.AuthController do
  use TwitchGameServerWeb, :controller

  alias TwitchGameServer.Accounts
  alias TwitchGameServerWeb.Auth.UserAuth

  def request(conn, %{"provider" => "twitch"}) do
    client = twitch_client() |> OAuth2.Client.put_param(:scope, "user:read:email")
    authorize_url = OAuth2.Client.authorize_url!(client)
    redirect(conn, external: authorize_url)
  end

  def callback(conn, %{"provider" => "twitch", "code" => code}) do
    client = twitch_client()

    twitch_token_params = %{
      client_id: client.client_id,
      client_secret: client.client_secret,
      code: code,
      grant_type: "authorization_code",
      redirect_uri: client.redirect_uri
    }

    client =
      client
      |> OAuth2.Client.merge_params(twitch_token_params)
      |> OAuth2.Client.get_token!()

    %{body: %{"data" => [user_data]}} =
      client
      |> OAuth2.Client.put_header("client-id", client.client_id)
      |> OAuth2.Client.get!("/helix/users")

    %{"display_name" => display_name, "email" => email, "id" => id} = user_data

    attrs = %{"display_name" => display_name, "email" => email, "twitch_id" => id}

    {:ok, user} =
      case Accounts.get_user_by_email(email) do
        nil -> Accounts.create_user_from_twitch(attrs)
        user -> Accounts.update_user_from_twitch(user, attrs)
      end

    conn
    |> UserAuth.log_in_user(user)
    |> redirect(to: ~p"/game")
  end

  defp twitch_client do
    config = Application.fetch_env!(:twitch_gameserver, __MODULE__)
    client_id = Keyword.fetch!(config, :twitch_client_id)
    client_secret = Keyword.fetch!(config, :twitch_client_secret)
    url = TwitchGameServerWeb.Endpoint.url()

    OAuth2.Client.new([
      strategy: OAuth2.Strategy.AuthCode, #default
      client_id: client_id,
      client_secret: client_secret,
      site: "https://api.twitch.tv",
      authorize_url: "https://id.twitch.tv/oauth2/authorize",
      redirect_uri: "#{url}/auth/twitch/callback",
      token_url: "https://id.twitch.tv/oauth2/token",
      token_method: :post,
      serializers: %{"application/json" => Jason}
    ])
  end
end
