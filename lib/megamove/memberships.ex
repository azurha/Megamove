defmodule Megamove.Memberships do
  @moduledoc """
  Le contexte Memberships gère les adhésions utilisateurs-organisations.
  """

  import Ecto.Query, warn: false
  alias Megamove.Repo
  alias Megamove.Memberships.Membership

  @doc """
  Retourne la liste des adhésions d'une organisation.
  """
  def list_memberships(org_id) do
    from(m in Membership, where: m.org_id == ^org_id)
    |> Repo.all()
  end

  @doc """
  Retourne la liste des organisations d'un utilisateur.
  """
  def list_user_organizations(user_id) do
    from(m in Membership,
      where: m.user_id == ^user_id,
      join: o in assoc(m, :organization),
      preload: [organization: o]
    )
    |> Repo.all()
  end

  @doc """
  Retourne une adhésion par son ID.
  """
  def get_membership!(id), do: Repo.get!(Membership, id)

  @doc """
  Retourne une adhésion par org_id et user_id.
  """
  def get_membership(org_id, user_id) do
    from(m in Membership, where: m.org_id == ^org_id and m.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Crée une adhésion.
  """
  def create_membership(attrs \\ %{}) do
    %Membership{}
    |> Membership.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Met à jour une adhésion.
  """
  def update_membership(%Membership{} = membership, attrs) do
    membership
    |> Membership.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Supprime une adhésion.
  """
  def delete_membership(%Membership{} = membership) do
    Repo.delete(membership)
  end

  @doc """
  Retourne un changeset vide pour une adhésion.
  """
  def change_membership(%Membership{} = membership, attrs \\ %{}) do
    Membership.changeset(membership, attrs)
  end

  @doc """
  Ajoute un utilisateur à une organisation.
  """
  def add_user_to_organization(org_id, user_id, role \\ :requester) do
    create_membership(%{
      org_id: org_id,
      user_id: user_id,
      org_role: role
    })
  end

  @doc """
  Retire un utilisateur d'une organisation.
  """
  def remove_user_from_organization(org_id, user_id) do
    case get_membership(org_id, user_id) do
      nil -> {:error, :not_found}
      membership -> delete_membership(membership)
    end
  end

  @doc """
  Change le rôle d'un utilisateur dans une organisation.
  """
  def change_user_role(org_id, user_id, new_role) do
    case get_membership(org_id, user_id) do
      nil -> {:error, :not_found}
      membership -> update_membership(membership, %{org_role: new_role})
    end
  end

  @doc """
  Vérifie si un utilisateur a un rôle spécifique dans une organisation.
  """
  def user_has_role?(org_id, user_id, required_role) do
    case get_membership(org_id, user_id) do
      %Membership{org_role: role} -> role == required_role
      nil -> false
    end
  end

  @doc """
  Vérifie si un utilisateur est propriétaire d'une organisation.
  """
  def user_is_owner?(org_id, user_id) do
    user_has_role?(org_id, user_id, :owner)
  end

  @doc """
  Vérifie si un utilisateur est admin d'une organisation.
  """
  def user_is_admin?(org_id, user_id) do
    user_has_role?(org_id, user_id, :admin) or user_is_owner?(org_id, user_id)
  end
end
