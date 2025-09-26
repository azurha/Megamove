defmodule Megamove.Repo.Migrations.CreateVehicles do
  use Ecto.Migration

  def change do
    create table(:vehicles, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :carrier_id, references(:carriers, type: :bigint), null: false
      add :vehicle_type, :string, null: false
      add :plate_number, :string, null: false
      add :capacity_weight_kg, :decimal, precision: 10, scale: 2
      add :capacity_volume_m3, :decimal, precision: 10, scale: 3
      add :pallets, :integer
      add :length_m, :decimal, precision: 6, scale: 2
      add :width_m, :decimal, precision: 6, scale: 2
      add :height_m, :decimal, precision: 6, scale: 2
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:vehicles, [:org_id, :plate_number])
    create index(:vehicles, [:org_id, :carrier_id])
    create index(:vehicles, [:org_id, :vehicle_type])

    # Contrainte CHECK pour vehicle_type
    create constraint(:vehicles, :vehicle_type_check, 
      check: "vehicle_type IN ('van', 'rigid', 'tractor', 'trailer', 'bike', 'other')")
  end
end
