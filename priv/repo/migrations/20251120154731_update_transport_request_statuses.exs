defmodule Megamove.Repo.Migrations.UpdateTransportRequestStatuses do
  use Ecto.Migration

  def up do
    # Supprimer l'ancienne contrainte
    drop constraint(:transport_requests, :status_check)

    # Mettre à jour les données existantes
    execute("""
      UPDATE transport_requests
      SET status = CASE
        WHEN status = 'draft' THEN 'published'
        WHEN status = 'cancelled' THEN 'litige'
        ELSE status
      END
      WHERE status IN ('draft', 'cancelled')
    """)

    # Créer la nouvelle contrainte avec les nouveaux statuts
    create constraint(:transport_requests, :status_check,
             check: "status IN ('published', 'quoted', 'booked', 'completed', 'litige')"
           )
  end

  def down do
    # Supprimer la nouvelle contrainte
    drop constraint(:transport_requests, :status_check)

    # Restaurer les anciennes valeurs si nécessaire
    execute("""
      UPDATE transport_requests
      SET status = CASE
        WHEN status = 'litige' THEN 'cancelled'
        WHEN status = 'published' AND inserted_at > NOW() - INTERVAL '1 day' THEN 'draft'
        ELSE status
      END
      WHERE status IN ('litige', 'published')
    """)

    # Recréer l'ancienne contrainte
    create constraint(:transport_requests, :status_check,
             check:
               "status IN ('draft', 'published', 'quoted', 'booked', 'cancelled', 'completed')"
           )
  end
end
