defmodule MegamoveWeb.HomeLive do
  use MegamoveWeb, :live_view

  alias MegamoveWeb.TransportRequestComponent
  alias Megamove.TransportRequests

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:active_tab, fn -> "demande_transport" end)
      |> assign_new(:departure, fn -> nil end)
      |> assign_new(:arrival, fn -> nil end)
      |> assign_new(:heavy_vehicle, fn -> false end)

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
    %{departure: departure, arrival: arrival, heavy_vehicle: heavy_vehicle, current_scope: current_scope} =
      socket.assigns

    cond do
      is_nil(current_scope) or is_nil(current_scope.user) ->
        {:noreply, put_flash(socket, :error, "Vous devez être connecté pour créer une demande.")}

      is_nil(departure) or is_nil(arrival) ->
        {:noreply, put_flash(socket, :error, "Veuillez sélectionner une adresse de départ et d'arrivée.")}

      true ->
        requested_vehicle_type = if heavy_vehicle, do: "truck", else: "auto"

        case TransportRequests.create_request_with_stops(
               current_scope,
               departure,
               arrival,
               requested_vehicle_type
             ) do
          {:ok, _request} ->
            {:noreply, put_flash(socket, :info, "Demande de transport créée." )}

          {:error, reason} ->
            {:noreply,
             put_flash(socket, :error, "Erreur lors de la création de la demande: #{inspect(reason)}")}
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
end
