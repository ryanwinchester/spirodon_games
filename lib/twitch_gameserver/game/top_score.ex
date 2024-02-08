defmodule TwitchGameServer.Game.TopScore do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "top_scores" do
    field :username, :string
    field :score, :integer
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:username, :score])
    |> validate_required([:username, :score])
    |> validate_greater_score()
  end

  defp validate_greater_score(changeset) do
    case {changeset.data.score, get_change(changeset, :score)} do
      {nil, _score} -> changeset
      {_existing, nil} -> add_error(changeset, :score, "must be greater than existing")
      {existing, score} when score > existing -> changeset
      {_existing, _score} -> add_error(changeset, :score, "must be greater than existing")
    end
  end
end
