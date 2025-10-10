defmodule Megamove.Organizations.Organization do
  @moduledoc """
  Schéma pour les organisations (expéditeurs, transporteurs, courtiers).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @org_types ~w[shipper carrier broker platform]a

  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :org_type, Ecto.Enum, values: @org_types
    field :address, :string
    field :city, :string
    field :postal_code, :string
    field :country, :string, default: "FR"
    field :phone, :string
    field :email, :string
    field :website, :string
    field :vat_number, :string
    field :siret, :string
    field :is_active, :boolean, default: true
    field :settings, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [
      :name,
      :slug,
      :org_type,
      :address,
      :city,
      :postal_code,
      :country,
      :phone,
      :email,
      :website,
      :vat_number,
      :siret,
      :is_active,
      :settings
    ])
    |> validate_required([:name, :slug, :org_type, :country])
    |> validate_inclusion(:org_type, @org_types)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "doit être un email valide")
    |> validate_format(:website, ~r/^https?:\/\/.+/,
      message: "doit commencer par http:// ou https://"
    )
    |> validate_length(:name, min: 2, max: 255)
    |> validate_length(:slug, min: 2, max: 100)
    |> validate_length(:city, max: 100)
    |> validate_length(:postal_code, max: 20)
    |> validate_length(:phone, max: 50)
    |> validate_length(:vat_number, max: 50)
    |> validate_length(:siret, max: 14)
    |> unique_constraint(:slug)
    |> unique_constraint(:email)
    |> unique_constraint(:vat_number)
    |> unique_constraint(:siret)
  end

  @doc """
  Génère un slug à partir du nom de l'organisation.
  """
  def generate_slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
