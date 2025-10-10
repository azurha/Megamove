defmodule Megamove.Repo.Migrations.CreateRoutes do
  use Ecto.Migration

  def change do
    create table(:routes, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :context_type, :string, null: false
      add :context_id, :bigint, null: false
      add :profile, :string, null: false
      add :distance_m, :decimal, precision: 12, scale: 2, null: false
      add :duration_s, :decimal, precision: 12, scale: 2, null: false
      add :polyline, :text
      add :valhalla_params, :map
      add :valhalla_raw_response, :map
      add :computed_at, :utc_datetime, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:routes, [:org_id, :context_type, :context_id])
    create index(:routes, [:org_id, :computed_at])

    # Contraintes CHECK
    create constraint(:routes, :context_type_check,
             check: "context_type IN ('transport_request', 'booking', 'assignment')"
           )

    create constraint(:routes, :profile_check,
             check: "profile IN ('auto', 'truck', 'bicycle', 'pedestrian')"
           )
  end
end
