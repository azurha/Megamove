defmodule Megamove.Places.Place do
  @moduledoc """
  Schéma pour les lieux/adresses des organisations.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "places" do
    field :name, :string
    field :address, :string
    field :city, :string
    field :postal_code, :string
    field :country, :string, default: "FR"
    field :lat, :decimal
    field :lng, :decimal
    field :geohash, :string

    # Relation avec l'organisation
    belongs_to :organization, Megamove.Organizations.Organization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(place, attrs) do
    place
    |> cast(attrs, [
      :name, :address, :city, :postal_code, :country, :lat, :lng, :geohash, :organization_id
    ])
    |> validate_required([:name, :address, :city, :country, :organization_id])
    |> validate_length(:name, min: 2, max: 255)
    |> validate_length(:address, min: 5, max: 500)
    |> validate_length(:city, min: 2, max: 100)
    |> validate_length(:postal_code, max: 20)
    |> validate_length(:country, min: 2, max: 3)
    |> validate_number(:lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:lng, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_length(:geohash, max: 12)
    |> foreign_key_constraint(:organization_id)
  end

  @doc """
  Génère un geohash à partir des coordonnées lat/lng.
  """
  def generate_geohash(lat, lng) when is_number(lat) and is_number(lng) do
    # Pour l'instant, on utilise une implémentation simple
    # En production, on pourrait utiliser une librairie comme :geohash
    geohash = "#{trunc(lat * 1000)}_#{trunc(lng * 1000)}"
    String.slice(geohash, 0, 12)  # Limiter à 12 caractères
  end

  @doc """
  Calcule la distance entre deux lieux en kilomètres (formule de Haversine).
  """
  def distance_between(%__MODULE__{lat: lat1, lng: lng1}, %__MODULE__{lat: lat2, lng: lng2}) do
    distance_between(lat1, lng1, lat2, lng2)
  end

  def distance_between(lat1, lng1, lat2, lng2) when is_number(lat1) and is_number(lng1) and is_number(lat2) and is_number(lng2) do
    # Rayon de la Terre en kilomètres
    r = 6371

    # Conversion en radians
    lat1_rad = lat1 * :math.pi() / 180
    lng1_rad = lng1 * :math.pi() / 180
    lat2_rad = lat2 * :math.pi() / 180
    lng2_rad = lng2 * :math.pi() / 180

    # Différences
    dlat = lat2_rad - lat1_rad
    dlng = lng2_rad - lng1_rad

    # Formule de Haversine
    a = :math.sin(dlat / 2) * :math.sin(dlat / 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) *
        :math.sin(dlng / 2) * :math.sin(dlng / 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    r * c
  end
end
