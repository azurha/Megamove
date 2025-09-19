defmodule Megamove.Repo.Migrations.CreateTransportRequestStops do
  use Ecto.Migration

  def change do
    create table(:transport_request_stops, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :transport_request_id, references(:transport_requests, type: :bigint), null: false
      add :position, :integer, null: false
      add :place_id, references(:places, type: :bigint)
      add :stop_type, :string, null: false
      add :time_window_start, :utc_datetime
      add :time_window_end, :utc_datetime
      add :instructions, :text
      add :contact_name, :string
      add :contact_phone, :string
      add :contact_email, :string
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:transport_request_stops, [:org_id, :transport_request_id, :position])
    create index(:transport_request_stops, [:org_id, :transport_request_id])
    create index(:transport_request_stops, [:org_id, :stop_type])

    # Contrainte CHECK pour stop_type
    create constraint(:transport_request_stops, :stop_type_check, 
      check: "stop_type IN ('pickup', 'dropoff', 'waypoint')")
  end
end
