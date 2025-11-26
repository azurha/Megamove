defmodule Megamove.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :org_id, references(:organizations, type: :bigint), null: false
      add :transport_request_id, references(:transport_requests, type: :bigint), null: false
      add :quote_id, references(:quotes, type: :bigint)
      add :sender_user_id, references(:users, type: :bigint), null: false
      add :content, :text, null: false
      add :read_at, :utc_datetime
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:messages, [:org_id, :transport_request_id])
    create index(:messages, [:org_id, :quote_id])
    create index(:messages, [:sender_user_id])
    create index(:messages, [:org_id, :inserted_at])
  end
end
