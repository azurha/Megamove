defmodule Megamove.TransportRequests do
  @moduledoc """
  Contexte pour la gestion des demandes de transport.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Megamove.Repo

  alias Megamove.TransportRequests.TransportRequest
  alias Megamove.TransportRequests.TransportRequestStop
  alias Megamove.Places.Place
  alias Phoenix.PubSub

  @type address_map :: %{label: String.t(), lat: number(), lon: number()}

  @spec create_request_with_stops(
          map(),
          address_map(),
          address_map(),
          String.t(),
          Decimal.t() | nil
        ) ::
          {:ok, TransportRequest.t()} | {:error, any()}
  def create_request_with_stops(
        current_scope,
        departure,
        arrival,
        requested_vehicle_type,
        distance_km \\ nil
      )
      when is_map(current_scope) and is_map(departure) and is_map(arrival) do
    org_id = current_scope.user.org_id
    user_id = current_scope.user.id

    Multi.new()
    |> Multi.run(:place_pickup, fn _repo, _changes ->
      create_place(org_id, departure)
    end)
    |> Multi.run(:place_dropoff, fn _repo, _changes ->
      create_place(org_id, arrival)
    end)
    |> Multi.insert(
      :request,
      TransportRequest.changeset(%TransportRequest{}, %{
        org_id: org_id,
        created_by_user_id: user_id,
        status: :published,
        shipment_type: :other,
        requested_vehicle_type: requested_vehicle_type,
        distance_km: distance_km
      })
    )
    |> Multi.insert(:stop_pickup, fn %{request: request, place_pickup: place_pickup} ->
      TransportRequestStop.changeset(%TransportRequestStop{}, %{
        org_id: org_id,
        transport_request_id: request.id,
        position: 0,
        place_id: place_pickup.id,
        stop_type: :pickup
      })
    end)
    |> Multi.insert(:stop_dropoff, fn %{request: request, place_dropoff: place_dropoff} ->
      TransportRequestStop.changeset(%TransportRequestStop{}, %{
        org_id: org_id,
        transport_request_id: request.id,
        position: 1,
        place_id: place_dropoff.id,
        stop_type: :dropoff
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{request: request}} ->
        broadcast_request_created(current_scope, request.id)
        {:ok, request}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp create_place(org_id, %{label: label, lat: lat, lon: lon}) do
    city =
      case extract_city(label) do
        nil -> fallback_city(label)
        "" -> fallback_city(label)
        city -> city
      end

    attrs = %{
      name: label,
      address: label,
      city: city,
      postal_code: nil,
      country: "FR",
      lat: lat,
      lng: lon,
      geohash: Place.generate_geohash(lat, lon),
      organization_id: org_id
    }

    %Place{}
    |> Place.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  S'abonne aux événements des demandes pour l'utilisateur courant.
  """
  @spec subscribe(map()) :: :ok | {:error, term()}
  def subscribe(%{user: %{id: user_id}}) do
    PubSub.subscribe(Megamove.PubSub, user_topic(user_id))
  end

  @doc false
  defp broadcast_request_created(%{user: %{id: user_id}}, request_id) do
    payload = fetch_request_with_places(request_id)
    PubSub.broadcast(Megamove.PubSub, user_topic(user_id), {:transport_request_created, payload})
  end

  defp user_topic(user_id), do: "users:" <> Integer.to_string(user_id) <> ":transport_requests"

  defp fetch_request_with_places(request_id) do
    from(tr in TransportRequest,
      where: tr.id == ^request_id,
      left_join: sp in TransportRequestStop,
      on: sp.transport_request_id == tr.id and sp.stop_type == ^:pickup,
      left_join: sp_place in Place,
      on: sp.place_id == sp_place.id,
      left_join: sd in TransportRequestStop,
      on: sd.transport_request_id == tr.id and sd.stop_type == ^:dropoff,
      left_join: sd_place in Place,
      on: sd.place_id == sd_place.id,
      select: %{request: tr, pickup_place: sp_place, dropoff_place: sd_place}
    )
    |> Repo.one()
  end

  defp extract_city(label) when is_binary(label) do
    label
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> List.first()
  end

  defp fallback_city(label) when is_binary(label) do
    tokens =
      label
      |> String.split([",", " "], trim: true)

    case tokens do
      [first | _] when is_binary(first) and byte_size(first) > 0 -> first
      _ -> "Inconnu"
    end
  end

  @doc """
  Liste les demandes de transport créées par l'utilisateur courant (dans `current_scope`).

  Retourne une liste de maps de la forme:
    %{request: %TransportRequest{}, pickup_place: %Place{} | nil, dropoff_place: %Place{} | nil}
  """
  @spec list_user_transport_requests(map()) ::
          [
            %{
              request: TransportRequest.t(),
              pickup_place: Place.t() | nil,
              dropoff_place: Place.t() | nil
            }
          ]
  def list_user_transport_requests(%{user: %{id: user_id}}) when is_integer(user_id) do
    from(tr in TransportRequest,
      where: tr.created_by_user_id == ^user_id,
      left_join: sp in TransportRequestStop,
      on: sp.transport_request_id == tr.id and sp.stop_type == ^:pickup,
      left_join: sp_place in Place,
      on: sp.place_id == sp_place.id,
      left_join: sd in TransportRequestStop,
      on: sd.transport_request_id == tr.id and sd.stop_type == ^:dropoff,
      left_join: sd_place in Place,
      on: sd.place_id == sd_place.id,
      order_by: [desc: tr.inserted_at],
      select: %{request: tr, pickup_place: sp_place, dropoff_place: sd_place}
    )
    |> Repo.all()
  end

  @doc """
  Supprime une demande de transport si elle appartient à l'utilisateur courant.

  Supprime également tous les stops associés.
  """
  @spec delete_transport_request(map(), integer()) ::
          {:ok, TransportRequest.t()} | {:error, term()}
  def delete_transport_request(%{user: %{id: user_id}}, request_id)
      when is_integer(user_id) and is_integer(request_id) do
    case Repo.get(TransportRequest, request_id) do
      nil ->
        {:error, :not_found}

      request ->
        if request.created_by_user_id == user_id do
          Multi.new()
          |> Multi.delete_all(
            :stops,
            from(trs in TransportRequestStop, where: trs.transport_request_id == ^request_id)
          )
          |> Multi.delete(:request, request)
          |> Repo.transaction()
          |> case do
            {:ok, %{request: request}} -> {:ok, request}
            {:error, _step, reason, _changes} -> {:error, reason}
          end
        else
          {:error, :forbidden}
        end
    end
  end
end
