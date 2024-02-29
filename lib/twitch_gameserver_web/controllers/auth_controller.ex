defmodule TwitchGameServerWeb.Auth.AuthController do
  use TwitchGameServerWeb, :controller

  alias TwitchGameServer.Accounts
  alias TwitchGameServerWeb.Auth.UserAuth

  @doc """
  Redirect to the OAuth2 provider's authorization URL.
  """
  def request(conn, %{"provider" => "twitch"}) do
    client = twitch_client() |> OAuth2.Client.put_param(:scope, "user:read:email")
    authorize_url = OAuth2.Client.authorize_url!(client)
    redirect(conn, external: authorize_url)
  end

  @doc """
  Callback to handle the provider's redirect back with the code for access
  token.
  """
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

    %{"email" => email} = user_attrs = user_attrs("twitch", user_data)

    # A cheeky little two-step user faux-upsert.
    {:ok, user} =
      case Accounts.get_user_by_email(email) do
        nil -> Accounts.create_user_from_twitch(user_attrs)
        user -> Accounts.update_user_from_twitch(user, user_attrs)
      end

    conn
    |> UserAuth.log_in_user(user)
    |> redirect(to: ~p"/game")
  end

  # Build the Twitch OAuth2 client.
  defp twitch_client do
    url = TwitchGameServerWeb.Endpoint.url()
    config = Application.fetch_env!(:twitch_gameserver, __MODULE__)

    client_id =
      Keyword.fetch!(config, :twitch_client_id) || raise "twitch_client_id not set"

    client_secret =
      Keyword.fetch!(config, :twitch_client_secret) || raise "twitch_client_secret not set"

    OAuth2.Client.new(
      # default
      strategy: OAuth2.Strategy.AuthCode,
      client_id: client_id,
      client_secret: client_secret,
      site: "https://api.twitch.tv",
      authorize_url: "https://id.twitch.tv/oauth2/authorize",
      redirect_uri: "#{url}/auth/twitch/callback",
      token_url: "https://id.twitch.tv/oauth2/token",
      token_method: :post,
      serializers: %{"application/json" => Jason}
    )
  end

  defp user_attrs("twitch", user_data) do
    %{"display_name" => display_name, "email" => email, "id" => id} = user_data

    %{
      "display_name" => display_name,
      "email" => email,
      "twitch_id" => id
    }
  end
end
