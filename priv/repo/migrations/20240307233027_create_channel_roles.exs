defmodule TwitchGameServer.Repo.Migrations.CreateChannelRoles do
  use Ecto.Migration

  def change do
    create table(:channel_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :channel, :string
      add :role, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:channel_roles, [:user_id])
  end
end
