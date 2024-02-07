import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

if twitch_user = System.get_env("TWITCH_USER") do
  twitch_channels = System.fetch_env!("TWITCH_CHANNELS") |> String.split(~r/,(\s*)?/)
  twitch_mod_channels = System.fetch_env!("TWITCH_MOD_CHANNELS") |> String.split(~r/,(\s*)?/)
  twitch_chat_token = System.fetch_env!("TWITCH_OAUTH_TOKEN")

  config :twitch_gameserver,
    bot: [
      bot: TwitchGameServer.TwitchChat,
      user: twitch_user,
      pass: twitch_chat_token,
      channels: twitch_channels,
      mod_channels: twitch_mod_channels
    ]
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/twitch_gameserver start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :twitch_gameserver, TwitchGameServerWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/twitch_gameserver/twitch_gameserver.db
      """

  config :twitch_gameserver, TwitchGameServer.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :twitch_gameserver, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :twitch_gameserver, TwitchGameServerWeb.Endpoint,
    # Test SSL works then force it. Test force works, then remove `expires` override.
    # force_ssl: [hsts: true, expires: 500],
    url: [host: host, port: 443, scheme: "https"],
    secret_key_base: secret_key_base

  # Optional SSL config.
  case port do
    443 ->
      config :twitch_gameserver, TwitchGameServerWeb.Endpoint,
        # Test SSL works then force it. Then remove `expires` override after it works.
        # force_ssl: [hsts: true, expires: 500],
        https: [
          port: 443,
          cipher_suite: :strong,
          keyfile: System.fetch_env!("GAMESERVER_SSL_KEY_PATH"),
          certfile: System.fetch_env!("GAMESERVER_SSL_CERT_PATH")
        ]

    port ->
      config :twitch_gameserver, TwitchGameServerWeb.Endpoint, http: [port: port]
  end
end
