defmodule Megamove.Repo.Migrations.CreateRouteWaypoints do
  use Ecto.Migration

  def change do
    create table(:route_waypoints, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :route_id, references(:routes, type: :bigint), null: false
      add :position, :integer, null: false
      add :place_id, references(:places, type: :bigint)
      add :lat, :decimal, precision: 10, scale: 8, null: false
      add :lng, :decimal, precision: 11, scale: 8, null: false
      add :name, :string
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:route_waypoints, [:org_id, :route_id, :position])
    create index(:route_waypoints, [:org_id, :route_id])
  end
end
