defmodule Megamove.Repo.Migrations.CreateTrackingEvents do
  use Ecto.Migration

  def change do
    create table(:tracking_events, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :booking_id, references(:bookings, type: :bigint), null: false
      add :assignment_id, references(:assignments, type: :bigint)
      add :stop_id, references(:transport_request_stops, type: :bigint)
      add :event_type, :string, null: false
      add :at, :utc_datetime, null: false
      add :lat, :decimal, precision: 10, scale: 8
      add :lng, :decimal, precision: 11, scale: 8
      add :accuracy_m, :decimal, precision: 8, scale: 2
      add :details, :map
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:tracking_events, [:org_id, :booking_id, :at])
    create index(:tracking_events, [:org_id, :event_type])
    create index(:tracking_events, [:org_id, :lat, :lng])

    # Contrainte CHECK pour event_type
    create constraint(:tracking_events, :event_type_check, 
      check: "event_type IN ('departed', 'arrived', 'loaded', 'unloaded', 'delivered', 'exception', 'delay')")
  end
end
