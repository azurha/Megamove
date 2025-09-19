defmodule Megamove.Repo.Migrations.CreateMemberships do
  use Ecto.Migration

  def change do
    create table(:memberships, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :user_id, references(:users, type: :bigint), null: false
      add :org_role, :string, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:memberships, [:org_id, :user_id])
    create index(:memberships, [:org_id])
    create index(:memberships, [:user_id])

    # Contrainte CHECK pour org_role
    create constraint(:memberships, :org_role_check, 
      check: "org_role IN ('owner', 'admin', 'member', 'viewer')")
  end
end
