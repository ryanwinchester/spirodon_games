defmodule TwitchGameServer.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, null: false
      add :total, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:scores, [:username])
  end
end
