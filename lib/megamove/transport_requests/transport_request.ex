defmodule Megamove.TransportRequests.TransportRequest do
  @moduledoc """
  Schéma pour les demandes de transport.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @statuses ~w[published quoted booked completed litige]a
  @shipment_types ~w[parcel pallet full_truck container other]a

  @type t :: %__MODULE__{}

  schema "transport_requests" do
    field :reference, :string
    field :status, Ecto.Enum, values: @statuses
    field :shipment_type, Ecto.Enum, values: @shipment_types
    field :cargo_description, :string
    field :cargo_weight_kg, :decimal
    field :cargo_volume_m3, :decimal
    field :hazmat, :boolean, default: false
    field :temperature_control, :boolean, default: false
    field :pickup_earliest_at, :utc_datetime
    field :pickup_latest_at, :utc_datetime
    field :delivery_earliest_at, :utc_datetime
    field :delivery_latest_at, :utc_datetime
    field :requested_vehicle_type, :string
    field :notes, :string
    field :distance_km, :decimal

    belongs_to :organization, Megamove.Organizations.Organization, foreign_key: :org_id
    belongs_to :created_by_user, Megamove.Accounts.User, foreign_key: :created_by_user_id

    has_many :quotes, Megamove.Quotes.Quote
    has_many :messages, Megamove.Messages.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [
      :org_id,
      :created_by_user_id,
      :reference,
      :status,
      :shipment_type,
      :cargo_description,
      :cargo_weight_kg,
      :cargo_volume_m3,
      :hazmat,
      :temperature_control,
      :pickup_earliest_at,
      :pickup_latest_at,
      :delivery_earliest_at,
      :delivery_latest_at,
      :requested_vehicle_type,
      :notes,
      :distance_km
    ])
    |> validate_required([:org_id, :created_by_user_id, :status, :shipment_type])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:shipment_type, @shipment_types)
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:created_by_user_id)
  end
end
