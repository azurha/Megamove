defmodule Megamove.Repo.Migrations.CreateRouteLegs do
  use Ecto.Migration

  def change do
    create table(:route_legs, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :route_id, references(:routes, type: :bigint), null: false
      add :position, :integer, null: false
      add :distance_m, :decimal, precision: 12, scale: 2, null: false
      add :duration_s, :decimal, precision: 12, scale: 2, null: false
      add :summary, :text
      add :polyline, :text
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:route_legs, [:org_id, :route_id, :position])
    create index(:route_legs, [:org_id, :route_id])
  end
end
