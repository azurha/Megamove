defmodule Megamove.Repo.Migrations.CreatePricingRules do
  use Ecto.Migration

  def change do
    create table(:pricing_rules, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :name, :string, null: false
      add :vehicle_type, :string
      add :base_fee_cents, :integer, null: false, default: 0
      add :per_km_cents, :integer, null: false, default: 0
      add :per_minute_cents, :integer, null: false, default: 0
      add :min_fee_cents, :integer, null: false, default: 0
      add :active, :boolean, null: false, default: true
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:pricing_rules, [:org_id, :active])
    create index(:pricing_rules, [:org_id, :vehicle_type])
  end
end
