defmodule Megamove.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    # Vérifier si la table users existe déjà
    execute """
            DO $$
            BEGIN
              IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
                CREATE TABLE users (
                  id BIGSERIAL PRIMARY KEY,
                  email CITEXT NOT NULL,
                  hashed_password VARCHAR(255),
                  confirmed_at TIMESTAMP(0),
                  inserted_at TIMESTAMP(0) NOT NULL,
                  updated_at TIMESTAMP(0) NOT NULL
                );
                CREATE UNIQUE INDEX users_email_index ON users (email);
              END IF;
            END
            $$;
            """,
            ""

    # Vérifier si la table users_tokens existe déjà
    execute """
            DO $$
            BEGIN
              IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users_tokens') THEN
                CREATE TABLE users_tokens (
                  id BIGSERIAL PRIMARY KEY,
                  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                  token BYTEA NOT NULL,
                  context VARCHAR(255) NOT NULL,
                  sent_to VARCHAR(255),
                  authenticated_at TIMESTAMP(0),
                  inserted_at TIMESTAMP(0) NOT NULL
                );
                CREATE INDEX users_tokens_user_id_index ON users_tokens (user_id);
                CREATE UNIQUE INDEX users_tokens_context_token_index ON users_tokens (context, token);
              END IF;
            END
            $$;
            """,
            ""
  end
end
