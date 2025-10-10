defmodule Megamove.Repo.Migrations.AddOrgIdToUsers do
  use Ecto.Migration

  def change do
    # D'abord, ajouter la colonne comme nullable
    alter table(:users) do
      add :org_id, references(:organizations, type: :bigint), null: true
    end

    # Créer un index temporaire
    create index(:users, [:org_id])

    # Créer une organisation par défaut pour les utilisateurs existants
    execute """
              INSERT INTO organizations (id, name, slug, org_type, country, is_active, inserted_at, updated_at)
              VALUES (1, 'Organisation par défaut', 'default-org', 'platform', 'FR', true, NOW(), NOW())
              ON CONFLICT (id) DO NOTHING;
            """,
            ""

    # Mettre à jour tous les utilisateurs existants avec l'org_id par défaut
    execute """
              UPDATE users SET org_id = 1 WHERE org_id IS NULL;
            """,
            ""

    # Maintenant, rendre la colonne NOT NULL (sans recréer la contrainte FK)
    execute "ALTER TABLE users ALTER COLUMN org_id SET NOT NULL;", ""

    # Créer l'index composite
    create index(:users, [:org_id, :email])
  end
end
