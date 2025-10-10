defmodule MegamoveWeb.TransportRequestComponent do
  @moduledoc """
  Composant LiveView pour créer des demandes de transport.

  Utilise les composants d'autocomplétion d'adresse pour la saisie des adresses
  de départ et d'arrivée, et affiche une carte centrée sur le trajet.
  """

  use MegamoveWeb, :live_component

  alias MegamoveWeb.AddressAutocompleteComponent
  alias MegamoveWeb.MapComponent
  alias Megamove.ValhallaService

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:departure_address, nil)
     |> assign(:arrival_address, nil)
     |> assign(:heavy_vehicle, false)
     |> assign(:markers, [])
     |> assign(:polylines, [])
     |> assign(:loading, false)
     |> assign(:error, nil)}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      cond do
        Map.has_key?(assigns, :departure) ->
          %{label: label, lat: lat, lon: lon} = assigns.departure

          socket
          |> assign(:departure_address, %{label: label, lat: lat, lon: lon})
          |> maybe_autoroute()
          |> update_map_display()

        Map.has_key?(assigns, :arrival) ->
          %{label: label, lat: lat, lon: lon} = assigns.arrival

          socket
          |> assign(:arrival_address, %{label: label, lat: lat, lon: lon})
          |> maybe_autoroute()
          |> update_map_display()

        true ->
          socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md border border-gray-200 p-6">
      <div class="flex flex-col lg:flex-row lg:items-stretch gap-6">
        <!-- Section des adresses -->
        <div class="flex-1 space-y-4">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Demande de Transport</h3>
          
    <!-- Adresse de départ -->
          <div>
            <label class="mb-2 flex items-center gap-2 text-sm font-medium text-gray-700">
              <.icon name="hero-map-pin" class="h-5 w-5 text-blue-500" /> Adresse de départ
            </label>
            <.live_component
              module={AddressAutocompleteComponent}
              id={@id <> "-departure"}
              placeholder="12 rue de l'Aubépine 32458 Flétri-le-Pinçon"
            />
          </div>
          
    <!-- Adresse d'arrivée -->
          <div>
            <label class="mb-2 flex items-center gap-2 text-sm font-medium text-gray-700">
              <.icon name="hero-map-pin" class="h-5 w-5 text-emerald-500" /> Adresse d'arrivée
            </label>
            <.live_component
              module={AddressAutocompleteComponent}
              id={@id <> "-arrival"}
              placeholder="2 Avenue des Marronniers 21000 Dijon"
            />
          </div>
          
    <!-- Checkbox poids lourd -->
          <div class="flex items-center">
            <input
              type="checkbox"
              id={@id <> "-heavy-vehicle"}
              phx-click="toggle_heavy_vehicle"
              phx-target={@myself}
              checked={@heavy_vehicle}
              class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label for={@id <> "-heavy-vehicle"} class="ml-2 block text-sm text-gray-700">
              Transport en poids lourd
            </label>
          </div>
          
    <!-- Erreurs -->
          <div :if={@error} class="pt-2 text-sm text-red-600">{@error}</div>
          
    <!-- Les libellés complets sont désormais affichés directement dans les champs ci-dessus -->
        </div>
        
    <!-- Section carte -->
        <div class="flex-1">
          <div class="h-full">
            <.live_component
              module={MapComponent}
              id={@id <> "-map"}
              markers={@markers}
              polylines={@polylines}
              fit={true}
              class="w-full h-full rounded-md border border-gray-200"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_heavy_vehicle", _params, socket) do
    new_flag = !socket.assigns.heavy_vehicle
    socket = socket |> assign(:heavy_vehicle, new_flag) |> assign(:error, nil)

    case {socket.assigns.departure_address, socket.assigns.arrival_address} do
      {%{lat: s_lat, lon: s_lon}, %{lat: e_lat, lon: e_lon}} ->
        costing = if(new_flag, do: "truck", else: "auto")

        case ValhallaService.route([{s_lat, s_lon}, {e_lat, e_lon}], costing: costing) do
          {:ok, result, _meta} ->
            shape = extract_shape(result)
            {:noreply, socket |> apply_shape(shape)}

          {:ok, result} ->
            shape = extract_shape(result)
            {:noreply, socket |> apply_shape(shape)}

          {:error, {:http_error, status, _body, _url}} ->
            {:noreply,
             assign(socket, :error, "Erreur HTTP #{status} lors du recalcul de l'itinéraire")}

          {:error, reason} ->
            {:noreply,
             assign(socket, :error, "Erreur lors du recalcul de l'itinéraire: #{inspect(reason)}")}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("confirm_route", _params, socket), do: {:noreply, socket}

  # Les sélections d'adresses sont relayées par la LiveView par send_update/2

  defp update_map_display(socket) do
    markers = []

    markers =
      if socket.assigns.departure_address do
        [
          %{
            lat: socket.assigns.departure_address.lat,
            lon: socket.assigns.departure_address.lon,
            label: "Départ: #{socket.assigns.departure_address.label}",
            color: "#3b82f6"
          }
          | markers
        ]
      else
        markers
      end

    markers =
      if socket.assigns.arrival_address do
        [
          %{
            lat: socket.assigns.arrival_address.lat,
            lon: socket.assigns.arrival_address.lon,
            label: "Arrivée: #{socket.assigns.arrival_address.label}",
            color: "#10b981"
          }
          | markers
        ]
      else
        markers
      end

    # Préserver une polyline existante (issue de Valhalla) et ne tracer une ligne droite
    # que s'il n'existe pas encore de polyline calculée
    polylines =
      cond do
        socket.assigns.polylines != [] ->
          socket.assigns.polylines

        socket.assigns.departure_address && socket.assigns.arrival_address ->
          [
            %{
              shape: [
                [socket.assigns.departure_address.lat, socket.assigns.departure_address.lon],
                [socket.assigns.arrival_address.lat, socket.assigns.arrival_address.lon]
              ],
              color: if(socket.assigns.heavy_vehicle, do: "#ef4444", else: "#3b82f6"),
              weight: if(socket.assigns.heavy_vehicle, do: 4, else: 2)
            }
          ]

        true ->
          []
      end

    socket
    |> assign(:markers, markers)
    |> assign(:polylines, polylines)
  end

  defp maybe_autoroute(socket) do
    case {socket.assigns.departure_address, socket.assigns.arrival_address} do
      {%{lat: s_lat, lon: s_lon}, %{lat: e_lat, lon: e_lon}} ->
        costing = if(socket.assigns.heavy_vehicle, do: "truck", else: "auto")

        case ValhallaService.route([{s_lat, s_lon}, {e_lat, e_lon}], costing: costing) do
          {:ok, result} -> apply_shape(socket, extract_shape(result))
          {:ok, result, _meta} -> apply_shape(socket, extract_shape(result))
          _ -> socket
        end

      _ ->
        socket
    end
  end

  defp apply_shape(socket, nil), do: assign(socket, :polylines, [])

  defp apply_shape(socket, shape) when is_binary(shape) do
    color = if(socket.assigns.heavy_vehicle, do: "#ef4444", else: "#3b82f6")
    weight = if(socket.assigns.heavy_vehicle, do: 4, else: 2)

    assign(socket, :polylines, [%{shape: shape, color: color, weight: weight}])
  end

  defp extract_shape(%{"trip" => %{"legs" => [first_leg | _]}}) do
    Map.get(first_leg, "shape")
  end

  defp extract_shape(_), do: nil
end
