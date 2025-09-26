defmodule Megamove.Repo.Migrations.UpdateOrganizationsToMatchSchema do
  use Ecto.Migration

  def change do
    # Ajouter les champs manquants selon DATABASE_SCHEMA.md
    alter table(:organizations) do
      add :locale, :string, null: false, default: "fr-FR"
      add :currency, :string, null: false, default: "EUR"
    end

    # Créer l'index sur locale et currency
    create index(:organizations, [:locale])
    create index(:organizations, [:currency])
  end
end
