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
    lat = String.to_float(lat)
    lon = String.to_float(lon)
    new_location = {lat, lon}
    
    updated_locations = socket.assigns.locations ++ [new_location]
    
    {:noreply, assign(socket, :locations, updated_locations)}
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
