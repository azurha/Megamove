defmodule Megamove.Repo.Migrations.UpdateMembershipRoles do
  use Ecto.Migration

  def up do
    # Supprimer les enregistrements avec des rôles obsolètes
    execute "DELETE FROM memberships WHERE org_role NOT IN ('owner', 'admin', 'dispatcher', 'driver', 'requester', 'viewer')"

    # Supprimer l'ancienne contrainte
    drop constraint(:memberships, :org_role_check)

    # Créer la nouvelle contrainte avec les nouveaux rôles
    create constraint(:memberships, :org_role_check,
             check:
               "org_role IN ('owner', 'admin', 'dispatcher', 'driver', 'requester', 'viewer')"
           )
  end

  def down do
    # Supprimer la nouvelle contrainte
    drop constraint(:memberships, :org_role_check)

    # Restaurer l'ancienne contrainte
    create constraint(:memberships, :org_role_check,
             check: "org_role IN ('owner', 'admin', 'member', 'viewer')"
           )
  end
end
