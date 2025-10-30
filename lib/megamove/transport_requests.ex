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

  @type address_map :: %{label: String.t(), lat: number(), lon: number()}

  @spec create_request_with_stops(map(), address_map(), address_map(), String.t()) ::
          {:ok, TransportRequest.t()} | {:error, any()}
  def create_request_with_stops(current_scope, departure, arrival, requested_vehicle_type)
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
    |> Multi.insert(:request,
      TransportRequest.changeset(%TransportRequest{}, %{
        org_id: org_id,
        created_by_user_id: user_id,
        status: :draft,
        shipment_type: :other,
        requested_vehicle_type: requested_vehicle_type
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
      {:ok, %{request: request}} -> {:ok, request}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp create_place(org_id, %{label: label, lat: lat, lon: lon}) do
    attrs = %{
      name: label,
      address: label,
      city: nil,
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
end
