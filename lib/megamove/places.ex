defmodule Megamove.Places do
  @moduledoc """
  Le contexte Places gère les lieux/adresses des organisations.
  """

  import Ecto.Query, warn: false
  alias Megamove.Repo
  alias Megamove.Places.Place

  @doc """
  Retourne la liste de tous les lieux d'une organisation.
  """
  def list_places(org_id) do
    from(p in Place, where: p.organization_id == ^org_id)
    |> Repo.all()
  end

  @doc """
  Retourne un lieu par son ID.
  """
  def get_place!(id), do: Repo.get!(Place, id)

  @doc """
  Retourne un lieu par son ID et son org_id.
  """
  def get_place!(id, org_id) do
    from(p in Place, where: p.id == ^id and p.organization_id == ^org_id)
    |> Repo.one!()
  end

  @doc """
  Crée un lieu.
  """
  def create_place(attrs \\ %{}) do
    attrs = maybe_generate_geohash(attrs)

    %Place{}
    |> Place.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Met à jour un lieu.
  """
  def update_place(%Place{} = place, attrs) do
    attrs = maybe_generate_geohash(attrs)

    place
    |> Place.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Supprime un lieu.
  """
  def delete_place(%Place{} = place) do
    Repo.delete(place)
  end

  @doc """
  Retourne un changeset vide pour un lieu.
  """
  def change_place(%Place{} = place, attrs \\ %{}) do
    Place.changeset(place, attrs)
  end

  @doc """
  Recherche des lieux par nom ou ville.
  """
  def search_places(org_id, query) when is_binary(query) do
    search_term = "%#{query}%"

    from(p in Place,
      where:
        p.organization_id == ^org_id and
          (ilike(p.name, ^search_term) or ilike(p.city, ^search_term)),
      order_by: [asc: p.name]
    )
    |> Repo.all()
  end

  @doc """
  Trouve les lieux proches d'une position donnée.
  """
  def find_nearby_places(org_id, lat, lng, radius_km \\ 50) do
    # Pour l'instant, on utilise une recherche simple par bounding box
    # En production, on pourrait utiliser PostGIS ou une recherche par geohash
    # Approximation: 1 degré ≈ 111 km
    lat_delta = radius_km / 111.0
    lng_delta = radius_km / (111.0 * :math.cos(lat * :math.pi() / 180))

    from(p in Place,
      where:
        p.organization_id == ^org_id and
          p.lat >= ^(lat - lat_delta) and p.lat <= ^(lat + lat_delta) and
          p.lng >= ^(lng - lng_delta) and p.lng <= ^(lng + lng_delta),
      order_by: [asc: p.name]
    )
    |> Repo.all()
  end

  @doc """
  Trouve les lieux dans une ville donnée.
  """
  def list_places_by_city(org_id, city) do
    from(p in Place,
      where: p.organization_id == ^org_id and ilike(p.city, ^city),
      order_by: [asc: p.name]
    )
    |> Repo.all()
  end

  @doc """
  Calcule la distance entre deux lieux.
  """
  def distance_between_places(place1, place2) do
    Place.distance_between(place1, place2)
  end

  # Fonctions privées

  defp maybe_generate_geohash(attrs) do
    case {Map.get(attrs, :lat), Map.get(attrs, :lng)} do
      {lat, lng} when is_number(lat) and is_number(lng) ->
        geohash = Place.generate_geohash(lat, lng)
        Map.put(attrs, :geohash, geohash)

      _ ->
        attrs
    end
  end
end
