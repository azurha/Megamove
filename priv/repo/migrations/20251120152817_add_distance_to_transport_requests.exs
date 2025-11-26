defmodule Megamove.Repo.Migrations.AddDistanceToTransportRequests do
  use Ecto.Migration

  def change do
    alter table(:transport_requests) do
      add :distance_km, :decimal, precision: 10, scale: 2
    end
  end
end
