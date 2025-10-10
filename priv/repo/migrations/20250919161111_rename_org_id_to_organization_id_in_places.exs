defmodule Megamove.Repo.Migrations.RenameOrgIdToOrganizationIdInPlaces do
  use Ecto.Migration

  def change do
    # Renommer la colonne seulement si elle existe (idempotent)
    execute """
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'places' AND column_name = 'org_id'
      ) THEN
        ALTER TABLE places RENAME COLUMN org_id TO organization_id;
      END IF;
    END
    $$;
    """

    # Supprimer les index sur org_id s'ils existent (idempotent)
    drop_if_exists index(:places, [:org_id])
    drop_if_exists index(:places, [:org_id, :city])
    drop_if_exists index(:places, [:org_id, :geohash])
    drop_if_exists index(:places, [:org_id, :lat, :lng])

    # Créer les index sur organization_id s'ils n'existent pas (idempotent)
    create_if_not_exists index(:places, [:organization_id])
    create_if_not_exists index(:places, [:organization_id, :city])
    create_if_not_exists index(:places, [:organization_id, :geohash])
    create_if_not_exists index(:places, [:organization_id, :lat, :lng])
  end
end
