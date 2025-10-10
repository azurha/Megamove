defmodule Megamove.Carriers.Carrier do
  @moduledoc """
  Schéma pour les transporteurs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @statuses ~w[active suspended pending]a

  schema "carriers" do
    field :legal_name, :string
    field :vat_number, :string
    field :dot_number, :string
    field :contact_email, :string
    field :contact_phone, :string
    field :status, Ecto.Enum, values: @statuses

    # Relation avec l'organisation
    belongs_to :organization, Megamove.Organizations.Organization, foreign_key: :org_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(carrier, attrs) do
    carrier
    |> cast(attrs, [
      :legal_name,
      :vat_number,
      :dot_number,
      :contact_email,
      :contact_phone,
      :status,
      :org_id
    ])
    |> validate_required([:legal_name, :status, :org_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_format(:contact_email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: "doit être un email valide"
    )
    |> validate_length(:legal_name, min: 2, max: 255)
    |> validate_length(:vat_number, max: 50)
    |> validate_length(:dot_number, max: 50)
    |> validate_length(:contact_phone, max: 50)
    |> unique_constraint([:org_id, :vat_number])
    |> foreign_key_constraint(:org_id)
  end
end
