defmodule Megamove.Repo.Migrations.CreatePlaces do
  use Ecto.Migration

  def change do
    create table(:places, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :organization_id, references(:organizations, type: :bigint), null: false
      add :name, :string, null: false
      add :address, :text, null: false
      add :city, :string, null: false
      add :postal_code, :string
      add :country, :string, null: false, default: "FR"
      add :lat, :decimal, precision: 10, scale: 7
      add :lng, :decimal, precision: 10, scale: 7
      add :geohash, :string, size: 12
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:places, [:organization_id])
    create index(:places, [:organization_id, :city])
    create index(:places, [:organization_id, :geohash])
    create index(:places, [:organization_id, :lat, :lng])
    create index(:places, [:lat, :lng])
  end
end
