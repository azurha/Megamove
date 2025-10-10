defmodule Megamove.Repo.Migrations.CreateQuotes do
  use Ecto.Migration

  def change do
    create table(:quotes, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :transport_request_id, references(:transport_requests, type: :bigint), null: false
      add :carrier_id, references(:carriers, type: :bigint), null: false
      add :price_cents, :integer, null: false
      add :currency, :string, null: false, default: "EUR"
      add :eta_pickup, :utc_datetime
      add :eta_delivery, :utc_datetime
      add :validity_expires_at, :utc_datetime
      add :status, :string, null: false
      add :notes, :text
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:quotes, [:org_id, :transport_request_id, :carrier_id])
    create index(:quotes, [:org_id, :transport_request_id])
    create index(:quotes, [:org_id, :status])
    create index(:quotes, [:carrier_id])

    # Contrainte CHECK pour status
    create constraint(:quotes, :status_check,
             check: "status IN ('proposed', 'withdrawn', 'accepted', 'expired', 'rejected')"
           )
  end
end
