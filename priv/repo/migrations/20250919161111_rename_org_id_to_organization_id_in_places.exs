defmodule Megamove.Repo.Migrations.RenameOrgIdToOrganizationIdInPlaces do
  use Ecto.Migration

  def change do
    # Renommer la colonne org_id en organization_id
    rename table(:places), :org_id, to: :organization_id
    
    # Recréer les index avec le nouveau nom
    drop index(:places, [:org_id])
    drop index(:places, [:org_id, :city])
    drop index(:places, [:org_id, :geohash])
    drop index(:places, [:org_id, :lat, :lng])
    
    create index(:places, [:organization_id])
    create index(:places, [:organization_id, :city])
    create index(:places, [:organization_id, :geohash])
    create index(:places, [:organization_id, :lat, :lng])
  end
end
