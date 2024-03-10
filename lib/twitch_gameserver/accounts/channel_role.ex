defmodule TwitchGameServer.Accounts.ChannelRole do
  use TwitchGameServer.Schema

  import Ecto.Changeset

  @roles ~w[broadcaster mod vip sub]a

  @derive {Jason.Encoder, only: [:channel, :role]}

  schema "channel_roles" do
    field :role, Ecto.Enum, values: @roles
    field :channel, :string
    field :user_id, :binary_id
    timestamps()
  end

  @doc false
  def changeset(channel_role, attrs) do
    channel_role
    |> cast(attrs, [:channel, :role])
    |> validate_required([:channel, :role])
  end

  @doc "Get all possible roles."
  def roles, do: @roles
end
