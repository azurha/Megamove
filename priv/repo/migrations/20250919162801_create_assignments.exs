defmodule Megamove.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :booking_id, references(:bookings, type: :bigint), null: false
      add :vehicle_id, references(:vehicles, type: :bigint), null: false
      add :driver_user_id, references(:users, type: :bigint)
      add :status, :string, null: false
      add :planned_start_at, :utc_datetime
      add :planned_end_at, :utc_datetime
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:assignments, [:org_id, :booking_id])
    create index(:assignments, [:org_id, :status])
    create index(:assignments, [:vehicle_id])
    create index(:assignments, [:driver_user_id])

    # Contrainte CHECK pour status
    create constraint(:assignments, :status_check,
             check: "status IN ('planned', 'en_route', 'arrived', 'completed', 'cancelled')"
           )
  end
end
