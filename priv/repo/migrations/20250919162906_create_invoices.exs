defmodule Megamove.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :booking_id, references(:bookings, type: :bigint), null: false
      add :total_cents, :integer, null: false
      add :currency, :string, null: false, default: "EUR"
      add :status, :string, null: false
      add :issued_at, :utc_datetime
      add :paid_at, :utc_datetime
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:invoices, [:org_id, :booking_id])
    create index(:invoices, [:org_id, :status])
    create index(:invoices, [:booking_id])

    # Contrainte CHECK pour status
    create constraint(:invoices, :status_check,
             check: "status IN ('draft', 'issued', 'paid', 'void')"
           )
  end
end
