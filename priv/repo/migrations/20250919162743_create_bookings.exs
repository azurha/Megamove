defmodule Megamove.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :transport_request_id, references(:transport_requests, type: :bigint), null: false
      add :quote_id, references(:quotes, type: :bigint), null: false
      add :booked_by_user_id, references(:users, type: :bigint), null: false
      add :status, :string, null: false
      add :booked_at, :utc_datetime, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:bookings, [:org_id, :transport_request_id])
    create index(:bookings, [:org_id, :status])
    create index(:bookings, [:quote_id])
    create index(:bookings, [:booked_by_user_id])

    # Contrainte CHECK pour status
    create constraint(:bookings, :status_check, 
      check: "status IN ('booked', 'in_transit', 'delivered', 'cancelled', 'failed')")
  end
end
