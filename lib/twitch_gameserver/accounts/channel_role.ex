defmodule TwitchGameServer.Accounts.ChannelRole do
  use TwitchGameServer.Schema

  alias TwitchGameServer.Accounts.User

  import Ecto.Changeset

  @roles ~w[broadcaster mod vip sub]a

  schema "channel_roles" do
    field :role, Ecto.Enum, values: @roles
    field :channel, :string
    belongs_to :user, User
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
