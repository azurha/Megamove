defmodule MegamoveWeb.HomeLive do
  use MegamoveWeb, :live_view

  alias MegamoveWeb.TransportRequestComponent
  alias Megamove.TransportRequests
  alias Megamove.ValhallaService

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:active_tab, fn -> "demande_transport" end)
      |> assign_new(:departure, fn -> nil end)
      |> assign_new(:arrival, fn -> nil end)
      |> assign_new(:heavy_vehicle, fn -> false end)

    # Abonnement aux demandes utilisateur pour mises à jour temps réel
    if connected?(socket) do
      case socket.assigns do
        %{current_scope: %{user: _}} -> TransportRequests.subscribe(socket.assigns.current_scope)
        _ -> :ok
      end
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        :if={@current_scope && @current_scope.user}
        module={MegamoveWeb.HomeComponents.Logiciel}
        id="logiciel"
        current_scope={@current_scope}
        active_tab={@active_tab}
      />
      <.live_component
        :if={!(@current_scope && @current_scope.user)}
        module={MegamoveWeb.HomeComponents.Default}
        id="default"
      />
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("create_transport_request", _params, socket) do
    %{
      departure: departure,
      arrival: arrival,
      heavy_vehicle: heavy_vehicle,
      current_scope: current_scope
    } =
      socket.assigns

    cond do
      is_nil(current_scope) or is_nil(current_scope.user) ->
        {:noreply, put_flash(socket, :error, "Vous devez être connecté pour créer une demande.")}

      is_nil(departure) or is_nil(arrival) ->
        {:noreply,
         put_flash(socket, :error, "Veuillez sélectionner une adresse de départ et d'arrivée.")}

      true ->
        requested_vehicle_type = if heavy_vehicle, do: "truck", else: "auto"
        costing = if heavy_vehicle, do: "truck", else: "auto"

        # Calculer l'itinéraire pour obtenir la distance
        distance_km =
          case ValhallaService.route([{departure.lat, departure.lon}, {arrival.lat, arrival.lon}],
                 costing: costing
               ) do
            {:ok, result} ->
              extract_distance(result)

            {:ok, result, _meta} ->
              extract_distance(result)

            _ ->
              nil
          end

        case TransportRequests.create_request_with_stops(
               current_scope,
               departure,
               arrival,
               requested_vehicle_type,
               distance_km
             ) do
          {:ok, _request} ->
            # Masquer le formulaire après création réussie
            send_update(
              MegamoveWeb.HomeComponents.TransportRequest,
              id: "transport-request",
              show_form: false
            )

            {:noreply, put_flash(socket, :info, "Demande de transport créée.")}

          {:error, reason} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Erreur lors de la création de la demande: #{inspect(reason)}"
             )}
        end
    end
  end

  @impl true
  def handle_info({:address_selected, %{id: id, label: label, lat: lat, lon: lon}}, socket) do
    which =
      cond do
        String.ends_with?(id, "-departure") -> :departure
        String.ends_with?(id, "-arrival") -> :arrival
        true -> :unknown
      end

    payload =
      case which do
        :departure -> %{departure: %{label: label, lat: lat, lon: lon}}
        :arrival -> %{arrival: %{label: label, lat: lat, lon: lon}}
        :unknown -> %{}
      end

    if payload != %{} do
      send_update(
        TransportRequestComponent,
        Keyword.merge([id: "transport-request-demo"], Map.to_list(payload))
      )
    end

    socket =
      case which do
        :departure -> assign(socket, :departure, %{label: label, lat: lat, lon: lon})
        :arrival -> assign(socket, :arrival, %{label: label, lat: lat, lon: lon})
        :unknown -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:heavy_vehicle, flag}, socket) do
    {:noreply, assign(socket, :heavy_vehicle, flag)}
  end

  @impl true
  def handle_info({:transport_request_created, _request_with_places}, socket) do
    # Forcer le rechargement complet du composant en passant un timestamp
    # Cela garantit que le stream sera rechargé depuis la base de données
    send_update(
      MegamoveWeb.HomeComponents.TransportRequest,
      id: "transport-request",
      current_scope: socket.assigns.current_scope,
      refresh_timestamp: System.system_time(:second)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:delete_transport_request, request_id}, socket) do
    case Map.get(socket.assigns, :current_scope) do
      %{user: _} = current_scope ->
        case TransportRequests.delete_transport_request(current_scope, request_id) do
          {:ok, _request} ->
            # Forcer le rechargement du composant pour mettre à jour le stream
            send_update(
              MegamoveWeb.HomeComponents.TransportRequest,
              id: "transport-request",
              current_scope: socket.assigns.current_scope,
              refresh_timestamp: System.system_time(:second)
            )

            {:noreply, put_flash(socket, :info, "Demande supprimée avec succès.")}

          {:error, reason} ->
            {:noreply,
             put_flash(socket, :error, "Erreur lors de la suppression: #{inspect(reason)}")}
        end

      _ ->
        {:noreply, socket}
    end
  end

  defp extract_distance(%{"trip" => %{"summary" => %{"length" => length}}})
       when is_number(length) do
    Decimal.from_float(length)
  end

  defp extract_distance(_), do: nil
end
