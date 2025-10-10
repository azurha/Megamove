defmodule Megamove.Organizations do
  @moduledoc """
  Le contexte Organizations gère les organisations (expéditeurs, transporteurs, courtiers).
  """

  import Ecto.Query, warn: false
  alias Megamove.Repo
  alias Megamove.Organizations.Organization

  @doc """
  Retourne la liste de toutes les organisations.
  """
  def list_organizations do
    Repo.all(Organization)
  end

  @doc """
  Retourne la liste des organisations actives.
  """
  def list_active_organizations do
    from(o in Organization, where: o.is_active == true)
    |> Repo.all()
  end

  @doc """
  Retourne une organisation par son ID.
  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Retourne une organisation par son slug.
  """
  def get_organization_by_slug(slug) do
    Repo.get_by(Organization, slug: slug)
  end

  @doc """
  Retourne une organisation par son email.
  """
  def get_organization_by_email(email) do
    Repo.get_by(Organization, email: email)
  end

  @doc """
  Crée une organisation.
  """
  def create_organization(attrs \\ %{}) do
    attrs = maybe_generate_slug(attrs)

    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Met à jour une organisation.
  """
  def update_organization(%Organization{} = organization, attrs) do
    attrs = maybe_generate_slug(attrs, organization)

    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Supprime une organisation.
  """
  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  @doc """
  Retourne un changeset vide pour une organisation.
  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end

  @doc """
  Active ou désactive une organisation.
  """
  def toggle_organization_status(%Organization{} = organization) do
    update_organization(organization, %{is_active: !organization.is_active})
  end

  @doc """
  Recherche des organisations par nom ou email.
  """
  def search_organizations(query) when is_binary(query) do
    search_term = "%#{query}%"

    from(o in Organization,
      where: ilike(o.name, ^search_term) or ilike(o.email, ^search_term),
      order_by: [asc: o.name]
    )
    |> Repo.all()
  end

  @doc """
  Filtre les organisations par type.
  """
  def list_organizations_by_type(org_type)
      when org_type in ~w[shipper carrier broker platform]a do
    from(o in Organization, where: o.org_type == ^org_type and o.is_active == true)
    |> Repo.all()
  end

  # Fonctions privées

  defp maybe_generate_slug(attrs, organization \\ nil) do
    case Map.get(attrs, :slug) do
      nil ->
        name = Map.get(attrs, :name) || (organization && organization.name)

        if name do
          Map.put(attrs, :slug, Organization.generate_slug(name))
        else
          attrs
        end

      _ ->
        attrs
    end
  end
end
