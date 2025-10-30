defmodule Megamove.TransportRequests.TransportRequestStop do
  @moduledoc """
  Schéma pour les arrêts d'une demande de transport.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @stop_types ~w[pickup dropoff waypoint]a

  schema "transport_request_stops" do
    field :position, :integer
    field :stop_type, Ecto.Enum, values: @stop_types
    field :time_window_start, :utc_datetime
    field :time_window_end, :utc_datetime
    field :instructions, :string
    field :contact_name, :string
    field :contact_phone, :string
    field :contact_email, :string

    belongs_to :organization, Megamove.Organizations.Organization, foreign_key: :org_id
    belongs_to :transport_request, Megamove.TransportRequests.TransportRequest
    belongs_to :place, Megamove.Places.Place

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(stop, attrs) do
    stop
    |> cast(attrs, [
      :org_id,
      :transport_request_id,
      :position,
      :place_id,
      :stop_type,
      :time_window_start,
      :time_window_end,
      :instructions,
      :contact_name,
      :contact_phone,
      :contact_email
    ])
    |> validate_required([:org_id, :transport_request_id, :position, :stop_type])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_inclusion(:stop_type, @stop_types)
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:transport_request_id)
    |> foreign_key_constraint(:place_id)
  end
end
