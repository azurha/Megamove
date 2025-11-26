defmodule Megamove.Messages.Message do
  @moduledoc """
  Schéma pour les messages de conversation entre demandeurs et transporteurs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @type t :: %__MODULE__{}

  schema "messages" do
    field :content, :string
    field :read_at, :utc_datetime

    belongs_to :organization, Megamove.Organizations.Organization, foreign_key: :org_id
    belongs_to :transport_request, Megamove.TransportRequests.TransportRequest
    belongs_to :quote, Megamove.Quotes.Quote
    belongs_to :sender_user, Megamove.Accounts.User, foreign_key: :sender_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :org_id,
      :transport_request_id,
      :quote_id,
      :sender_user_id,
      :content,
      :read_at
    ])
    |> validate_required([:org_id, :transport_request_id, :sender_user_id, :content])
    |> validate_length(:content, min: 1, max: 5000)
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:transport_request_id)
    |> foreign_key_constraint(:quote_id)
    |> foreign_key_constraint(:sender_user_id)
  end
end
