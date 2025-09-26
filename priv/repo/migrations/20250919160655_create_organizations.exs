defmodule Megamove.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :org_type, :string, null: false
      add :address, :text
      add :city, :string
      add :postal_code, :string
      add :country, :string, null: false, default: "FR"
      add :phone, :string
      add :email, :string
      add :website, :string
      add :vat_number, :string
      add :siret, :string
      add :is_active, :boolean, null: false, default: true
      add :settings, :map, null: false, default: %{}
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:organizations, [:slug])
    create unique_index(:organizations, [:email], where: "email IS NOT NULL")
    create unique_index(:organizations, [:vat_number], where: "vat_number IS NOT NULL")
    create unique_index(:organizations, [:siret], where: "siret IS NOT NULL")
    create index(:organizations, [:org_type])
    create index(:organizations, [:is_active])
    create index(:organizations, [:country])

    # Contrainte CHECK pour org_type
    create constraint(:organizations, :org_type_check, 
      check: "org_type IN ('shipper', 'carrier', 'broker', 'platform')")
  end
end
