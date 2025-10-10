defmodule Megamove.Repo.Migrations.CreateCarriers do
  use Ecto.Migration

  def change do
    create table(:carriers, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :legal_name, :string, null: false
      add :vat_number, :string
      add :dot_number, :string
      add :contact_email, :string
      add :contact_phone, :string
      add :status, :string, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:carriers, [:org_id, :vat_number], where: "vat_number IS NOT NULL")
    create index(:carriers, [:org_id])
    create index(:carriers, [:status])

    # Contrainte CHECK pour status
    create constraint(:carriers, :status_check,
             check: "status IN ('active', 'suspended', 'pending')"
           )
  end
end
