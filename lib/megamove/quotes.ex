defmodule Megamove.Quotes do
  @moduledoc """
  Contexte pour la gestion des devis/offres des transporteurs.
  """

  import Ecto.Query, warn: false
  alias Megamove.Repo

  alias Megamove.Quotes.Quote

  @doc """
  Crée un nouveau devis.
  """
  @spec create_quote(map(), map()) :: {:ok, Quote.t()} | {:error, Ecto.Changeset.t()}
  def create_quote(current_scope, attrs) do
    org_id = current_scope.user.org_id

    %Quote{}
    |> Quote.changeset(
      Map.merge(attrs, %{
        "org_id" => org_id,
        "status" => "proposed"
      })
    )
    |> Repo.insert()
  end

  @doc """
  Liste les devis pour une demande de transport donnée.
  """
  @spec list_quotes_for_transport_request(integer()) :: [Quote.t()]
  def list_quotes_for_transport_request(transport_request_id) do
    from(q in Quote,
      where: q.transport_request_id == ^transport_request_id,
      order_by: [desc: q.inserted_at],
      preload: [:carrier]
    )
    |> Repo.all()
  end

  @doc """
  Récupère un devis par son ID.
  """
  @spec get_quote(integer()) :: Quote.t() | nil
  def get_quote(quote_id) do
    from(q in Quote,
      where: q.id == ^quote_id,
      preload: [:carrier, :transport_request]
    )
    |> Repo.one()
  end

  @doc """
  Met à jour le statut d'un devis.
  """
  @spec update_quote_status(integer(), String.t(), map()) ::
          {:ok, Quote.t()} | {:error, Ecto.Changeset.t()}
  def update_quote_status(quote_id, status, current_scope) do
    case Repo.get(Quote, quote_id) do
      nil ->
        {:error, :not_found}

      quote ->
        if quote.org_id == current_scope.user.org_id do
          quote
          |> Quote.changeset(%{status: status})
          |> Repo.update()
        else
          {:error, :forbidden}
        end
    end
  end
end
