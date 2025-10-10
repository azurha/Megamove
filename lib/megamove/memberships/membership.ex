defmodule Megamove.Memberships.Membership do
  @moduledoc """
  Schéma pour les adhésions utilisateurs-organisations.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  @org_roles ~w[owner admin dispatcher driver requester viewer]a

  schema "memberships" do
    field :org_role, Ecto.Enum, values: @org_roles

    # Relations
    belongs_to :organization, Megamove.Organizations.Organization, foreign_key: :org_id
    belongs_to :user, Megamove.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:org_role, :org_id, :user_id])
    |> validate_required([:org_role, :org_id, :user_id])
    |> validate_inclusion(:org_role, @org_roles)
    |> unique_constraint([:org_id, :user_id])
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:user_id)
  end
end
