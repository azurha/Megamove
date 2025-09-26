defmodule Megamove.Repo.Migrations.CreateTransportRequests do
  use Ecto.Migration

  def change do
    create table(:transport_requests, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :created_by_user_id, references(:users, type: :bigint), null: false
      add :reference, :string
      add :status, :string, null: false
      add :shipment_type, :string, null: false
      add :cargo_description, :text
      add :cargo_weight_kg, :decimal, precision: 10, scale: 2
      add :cargo_volume_m3, :decimal, precision: 10, scale: 3
      add :hazmat, :boolean, null: false, default: false
      add :temperature_control, :boolean, null: false, default: false
      add :pickup_earliest_at, :utc_datetime
      add :pickup_latest_at, :utc_datetime
      add :delivery_earliest_at, :utc_datetime
      add :delivery_latest_at, :utc_datetime
      add :requested_vehicle_type, :string
      add :notes, :text
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:transport_requests, [:org_id, :reference], where: "reference IS NOT NULL")
    create index(:transport_requests, [:org_id, :status])
    create index(:transport_requests, [:org_id, :inserted_at])
    create index(:transport_requests, [:created_by_user_id])

    # Contraintes CHECK
    create constraint(:transport_requests, :status_check, 
      check: "status IN ('draft', 'published', 'quoted', 'booked', 'cancelled', 'completed')")
    
    create constraint(:transport_requests, :shipment_type_check, 
      check: "shipment_type IN ('parcel', 'pallet', 'full_truck', 'container', 'other')")
  end
end
