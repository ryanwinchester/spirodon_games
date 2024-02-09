defmodule TwitchGameServer.Game.Score do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

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
    |> validate_number(:total, greater_than_or_equal_to: 0)
  end
end
