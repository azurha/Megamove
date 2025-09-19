defmodule Megamove.Carriers do
  @moduledoc """
  Le contexte Carriers gère les transporteurs.
  """

  import Ecto.Query, warn: false
  alias Megamove.Repo
  alias Megamove.Carriers.Carrier

  @doc """
  Retourne la liste des transporteurs d'une organisation.
  """
  def list_carriers(org_id) do
    from(c in Carrier, where: c.org_id == ^org_id)
    |> Repo.all()
  end

  @doc """
  Retourne la liste des transporteurs actifs d'une organisation.
  """
  def list_active_carriers(org_id) do
    from(c in Carrier, where: c.org_id == ^org_id and c.status == :active)
    |> Repo.all()
  end

  @doc """
  Retourne un transporteur par son ID.
  """
  def get_carrier!(id), do: Repo.get!(Carrier, id)

  @doc """
  Retourne un transporteur par son ID et son org_id.
  """
  def get_carrier!(id, org_id) do
    from(c in Carrier, where: c.id == ^id and c.org_id == ^org_id)
    |> Repo.one!()
  end

  @doc """
  Crée un transporteur.
  """
  def create_carrier(attrs \\ %{}) do
    %Carrier{}
    |> Carrier.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Met à jour un transporteur.
  """
  def update_carrier(%Carrier{} = carrier, attrs) do
    carrier
    |> Carrier.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Supprime un transporteur.
  """
  def delete_carrier(%Carrier{} = carrier) do
    Repo.delete(carrier)
  end

  @doc """
  Retourne un changeset vide pour un transporteur.
  """
  def change_carrier(%Carrier{} = carrier, attrs \\ %{}) do
    Carrier.changeset(carrier, attrs)
  end

  @doc """
  Recherche des transporteurs par nom ou numéro TVA.
  """
  def search_carriers(org_id, query) when is_binary(query) do
    search_term = "%#{query}%"
    
    from(c in Carrier,
      where: c.org_id == ^org_id and 
             (ilike(c.legal_name, ^search_term) or ilike(c.vat_number, ^search_term)),
      order_by: [asc: c.legal_name]
    )
    |> Repo.all()
  end

  @doc """
  Change le statut d'un transporteur.
  """
  def change_carrier_status(%Carrier{} = carrier, new_status) when new_status in [:active, :suspended, :pending] do
    update_carrier(carrier, %{status: new_status})
  end

  @doc """
  Suspend un transporteur.
  """
  def suspend_carrier(%Carrier{} = carrier) do
    change_carrier_status(carrier, :suspended)
  end

  @doc """
  Active un transporteur.
  """
  def activate_carrier(%Carrier{} = carrier) do
    change_carrier_status(carrier, :active)
  end
end
