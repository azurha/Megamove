defmodule MegamoveWeb.ValhallaDemoLive do
  @moduledoc """
  Page de démonstration des fonctionnalités Valhalla pour l'optimisation d'itinéraires.
  """

  use MegamoveWeb, :live_view

  alias Megamove.ValhallaService

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Démonstration Valhalla")
     |> assign(:locations, [])
     |> assign(:route_result, nil)
     |> assign(:optimized_route_result, nil)
     |> assign(:isochrone_result, nil)
     |> assign(:loading, false)
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("add_location", %{"lat" => lat, "lon" => lon}, socket) do
    case {lat, lon} do
      {"", ""} ->
        {:noreply, assign(socket, :error, "Veuillez saisir des coordonnées valides")}
      
      {lat_str, lon_str} when lat_str != "" and lon_str != "" ->
        case {Float.parse(lat_str), Float.parse(lon_str)} do
          {{lat_val, ""}, {lon_val, ""}} ->
            new_location = {lat_val, lon_val}
            updated_locations = socket.assigns.locations ++ [new_location]
            {:noreply, socket |> assign(:locations, updated_locations) |> assign(:error, nil)}
          
          _ ->
            {:noreply, assign(socket, :error, "Format de coordonnées invalide")}
        end
      
      _ ->
        {:noreply, assign(socket, :error, "Veuillez saisir les deux coordonnées")}
    end
  end

  @impl true
  def handle_event("remove_location", %{"index" => index}, socket) do
    index = String.to_integer(index)
    updated_locations = List.delete_at(socket.assigns.locations, index)

    {:noreply, assign(socket, :locations, updated_locations)}
  end

  @impl true
  def handle_event("clear_locations", _params, socket) do
    {:noreply, assign(socket, :locations, [])}
  end

  @impl true
  def handle_event("calculate_route", _params, socket) do
    if length(socket.assigns.locations) >= 2 do
      socket = socket |> assign(:loading, true) |> assign(:error, nil)

      case ValhallaService.route(socket.assigns.locations) do
        {:ok, result} ->
          {:noreply, socket |> assign(:route_result, result) |> assign(:loading, false)}
        {:error, reason} ->
          {:noreply, socket |> assign(:error, "Erreur lors du calcul de l'itinéraire: #{inspect(reason)}") |> assign(:loading, false)}
      end
    else
      {:noreply, assign(socket, :error, "Au moins 2 points sont nécessaires pour calculer un itinéraire")}
    end
  end

  @impl true
  def handle_event("calculate_route_bicycle", _params, socket) do
    if length(socket.assigns.locations) >= 2 do
      socket = socket |> assign(:loading, true) |> assign(:error, nil)

      case ValhallaService.route(socket.assigns.locations, costing: "bicycle") do
        {:ok, result} ->
          {:noreply, socket |> assign(:route_result, result) |> assign(:loading, false)}
        {:error, reason} ->
          {:noreply, socket |> assign(:error, "Erreur lors du calcul de l'itinéraire vélo: #{inspect(reason)}") |> assign(:loading, false)}
      end
    else
      {:noreply, assign(socket, :error, "Au moins 2 points sont nécessaires pour calculer un itinéraire")}
    end
  end

  @impl true
  def handle_event("calculate_route_pedestrian", _params, socket) do
    if length(socket.assigns.locations) >= 2 do
      socket = socket |> assign(:loading, true) |> assign(:error, nil)

      case ValhallaService.route(socket.assigns.locations, costing: "pedestrian") do
        {:ok, result} ->
          {:noreply, socket |> assign(:route_result, result) |> assign(:loading, false)}
        {:error, reason} ->
          {:noreply, socket |> assign(:error, "Erreur lors du calcul de l'itinéraire piéton: #{inspect(reason)}") |> assign(:loading, false)}
      end
    else
      {:noreply, assign(socket, :error, "Au moins 2 points sont nécessaires pour calculer un itinéraire")}
    end
  end

  @impl true
  def handle_event("calculate_optimized_route", _params, socket) do
    if length(socket.assigns.locations) >= 3 do
      socket = socket |> assign(:loading, true) |> assign(:error, nil)

      case ValhallaService.optimized_route(socket.assigns.locations) do
        {:ok, result} ->
          {:noreply, socket |> assign(:optimized_route_result, result) |> assign(:loading, false)}
        {:error, reason} ->
          {:noreply, socket |> assign(:error, "Erreur lors du calcul de l'itinéraire optimisé: #{inspect(reason)}") |> assign(:loading, false)}
      end
    else
      {:noreply, assign(socket, :error, "Au moins 3 points sont nécessaires pour l'optimisation d'itinéraire")}
    end
  end

  @impl true
  def handle_event("calculate_isochrone", _params, socket) do
    if length(socket.assigns.locations) >= 1 do
      socket = socket |> assign(:loading, true) |> assign(:error, nil)
      location = List.first(socket.assigns.locations)
      contours = [%{time: 15}]

      case ValhallaService.isochrone(location, contours) do
        {:ok, result} ->
          {:noreply, socket |> assign(:isochrone_result, result) |> assign(:loading, false)}
        {:error, reason} ->
          {:noreply, socket |> assign(:error, "Erreur lors du calcul de l'isochrone: #{inspect(reason)}") |> assign(:loading, false)}
      end
    else
      {:noreply, assign(socket, :error, "Au moins 1 point est nécessaire pour calculer une isochrone")}
    end
  end

  @impl true
  def handle_event("clear_results", _params, socket) do
    {:noreply,
     socket
     |> assign(:route_result, nil)
     |> assign(:optimized_route_result, nil)
     |> assign(:isochrone_result, nil)
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("load_example_detroit_buffalo", _params, socket) do
    # Exemple de la documentation Valhalla : Detroit → Buffalo
    locations = [
      {42.358528, -83.271400},  # Detroit, Michigan
      {42.996613, -78.749855}   # Buffalo, New York
    ]
    
    {:noreply, socket |> assign(:locations, locations) |> assign(:error, nil)}
  end

  @impl true
  def handle_event("load_example_paris", _params, socket) do
    # Exemple Paris avec 3 points pour tester l'optimisation TSP
    locations = [
      {48.8566, 2.3522},   # Tour Eiffel
      {48.8606, 2.3376},   # Arc de Triomphe
      {48.8534, 2.3488}    # Notre-Dame
    ]
    
    {:noreply, socket |> assign(:locations, locations) |> assign(:error, nil)}
  end

  @impl true
  def handle_event("load_example_nyc", _params, socket) do
    # Exemple NYC pour test multimodal
    locations = [
      {40.730930, -73.991379},  # Wanamaker Place
      {40.749706, -73.991562}   # Penn Plaza
    ]
    
    {:noreply, socket |> assign(:locations, locations) |> assign(:error, nil)}
  end

  defp format_coordinate({lat, lon}) do
    "#{Float.round(lat, 6)}, #{Float.round(lon, 6)}"
  end

  defp format_duration(seconds) do
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    remaining_minutes = rem(minutes, 60)

    cond do
      hours > 0 -> "#{hours}h #{remaining_minutes}min"
      true -> "#{minutes}min"
    end
  end

  defp format_distance(km) do
    if km < 1 do
      "#{Float.round(km * 1000, 0)}m"
    else
      "#{Float.round(km, 2)}km"
    end
  end
end
