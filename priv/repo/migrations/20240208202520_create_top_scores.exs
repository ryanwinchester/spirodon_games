defmodule TwitchGameServer.Repo.Migrations.CreateTopScores do
  use Ecto.Migration

  def change do
    create table(:top_scores, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string
      add :score, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:top_scores, [:username])
  end
end
