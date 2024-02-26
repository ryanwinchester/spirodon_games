import Config

config :twitch_gameserver, TwitchGameServer.Mailer, adapter: Swoosh.Adapters.Test

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :twitch_gameserver, TwitchGameServer.Repo,
  database: "twitch_gameserver_test#{System.get_env("MIX_TEST_PARTITION")}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :twitch_gameserver, TwitchGameServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "0nHoK8mjysvrAp+k/NBa64eCoQGvbAxogI0aAczIe9rY8PAnEOfkQ8SjqyC8w9Jn",
  server: true

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
