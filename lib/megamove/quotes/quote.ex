defmodule Megamove.Quotes.Quote do
  @moduledoc """
  Schéma pour les devis/offres des transporteurs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @statuses ~w[proposed withdrawn accepted expired rejected]a

  @type t :: %__MODULE__{}

  schema "quotes" do
    field :price_cents, :integer
    field :currency, :string, default: "EUR"
    field :eta_pickup, :utc_datetime
    field :eta_delivery, :utc_datetime
    field :validity_expires_at, :utc_datetime
    field :status, Ecto.Enum, values: @statuses
    field :notes, :string

    belongs_to :organization, Megamove.Organizations.Organization, foreign_key: :org_id
    belongs_to :transport_request, Megamove.TransportRequests.TransportRequest
    belongs_to :carrier, Megamove.Carriers.Carrier

    has_many :messages, Megamove.Messages.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [
      :org_id,
      :transport_request_id,
      :carrier_id,
      :price_cents,
      :currency,
      :eta_pickup,
      :eta_delivery,
      :validity_expires_at,
      :status,
      :notes
    ])
    |> validate_required([:org_id, :transport_request_id, :carrier_id, :price_cents, :currency, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:price_cents, greater_than: 0)
    |> validate_length(:currency, is: 3)
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:transport_request_id)
    |> foreign_key_constraint(:carrier_id)
  end
end
