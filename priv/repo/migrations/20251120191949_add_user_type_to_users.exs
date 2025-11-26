defmodule Megamove.Repo.Migrations.AddUserTypeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :user_type, :string, null: false, default: "particulier"
    end

    # Contrainte CHECK pour user_type
    create constraint(:users, :user_type_check,
             check: "user_type IN ('particulier', 'entreprise_professionnelle', 'chauffeur')"
           )
  end
end
