defmodule TwitchGameServer.Game.Score do
  use TwitchGameServer.Schema

  import Ecto.Changeset

  schema "scores" do
    field :username, :string
    field :total, :integer
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:username, :total])
    |> validate_required([:username, :total])
  end
end
