defmodule TwitchGameServer.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TwitchGameServer.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_display_name, do: "JohnDoe"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      display_name: valid_user_display_name(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> TwitchGameServer.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a channel_role.
  """
  def channel_role_fixture(attrs \\ %{}) do
    {:ok, channel_role} =
      attrs
      |> Enum.into(%{
        channel: "some_channel",
        role: "sub"
      })
      |> TwitchGameServer.Accounts.create_channel_role()

    channel_role
  end
end
