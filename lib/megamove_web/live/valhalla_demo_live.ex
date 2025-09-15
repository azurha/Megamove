defmodule MegamoveWeb.ValhallaDemoLive do
  @moduledoc """
  Page de démonstration des fonctionnalités Valhalla pour l'optimisation d'itinéraires.
  """

  use MegamoveWeb, :live_view

  alias Megamove.ValhallaService

  @impl true
  def mount(_params, _session, socket) do
    # Points par défaut : Dijon et Lyon
    default_locations = [
      # Dijon
      {47.3220, 5.0415},
      # Lyon
      {45.7640, 4.8357}
    ]

    {:ok,
     socket
     |> assign(:page_title, "Test API Valhalla - Route Dijon-Lyon")
     |> assign(:locations, default_locations)
     |> assign(:route_result, nil)
     |> assign(:loading, false)
     |> assign(:error, nil)
     |> assign(:request_url, nil)
     |> assign(:raw_response, nil)
     |> assign(:map_shape, nil)}
  end

  @impl true
  def handle_event("update_location", %{"lat" => lat, "lon" => lon, "index" => index}, socket) do
    case {lat, lon} do
      {"", ""} ->
        {:noreply, assign(socket, :error, "Veuillez saisir des coordonnées valides")}

      {lat_str, lon_str} when lat_str != "" and lon_str != "" ->
        case {Float.parse(lat_str), Float.parse(lon_str)} do
          {{lat_val, ""}, {lon_val, ""}} ->
            index = String.to_integer(index)
            new_location = {lat_val, lon_val}
            updated_locations = List.replace_at(socket.assigns.locations, index, new_location)
            socket = socket |> assign(:locations, updated_locations) |> assign(:error, nil)

            {:noreply, socket}

          _ ->
            {:noreply, assign(socket, :error, "Format de coordonnées invalide")}
        end

      _ ->
        {:noreply, assign(socket, :error, "Veuillez saisir les deux coordonnées")}
    end
  end

  @impl true
  def handle_event("calculate_route", _params, socket) do
    if length(socket.assigns.locations) >= 2 do
      socket = socket |> assign(:loading, true) |> assign(:error, nil)

      case ValhallaService.route(socket.assigns.locations, debug: true) do
        {:ok, result, %{url: url, raw: raw_body}} ->
          shape = extract_shape(result)

          socket =
            socket
            |> assign(:route_result, result)
            |> assign(:request_url, url)
            |> assign(:raw_response, raw_body)
            |> assign(:map_shape, shape)
            |> assign(:loading, false)

          socket = socket

          {:noreply, socket}

        {:ok, result} ->
          shape = extract_shape(result)

          socket =
            socket
            |> assign(:route_result, result)
            |> assign(:request_url, nil)
            |> assign(:raw_response, nil)
            |> assign(:map_shape, shape)
            |> assign(:loading, false)

          socket = socket

          {:noreply, socket}

        {:error, {:http_error, status, body, url}} ->
          {:noreply,
           socket
           |> assign(:error, "Erreur HTTP #{status} lors du calcul de l'itinéraire")
           |> assign(:request_url, url)
           |> assign(:raw_response, body)
           |> assign(:loading, false)}

        {:error, reason} ->
          {:noreply,
           socket
           |> assign(:error, "Erreur lors du calcul de l'itinéraire: #{inspect(reason)}")
           |> assign(:loading, false)}
      end
    else
      {:noreply,
       assign(socket, :error, "Au moins 2 points sont nécessaires pour calculer un itinéraire")}
    end
  end

  @impl true
  def handle_event("clear_results", _params, socket) do
    {:noreply,
     socket
     |> assign(:route_result, nil)
     |> assign(:error, nil)
     |> assign(:request_url, nil)
     |> assign(:raw_response, nil)
     |> assign(:map_shape, nil)}
  end

  defp format_coordinate({lat, lon}) do
    "#{Float.round(lat, 6)}, #{Float.round(lon, 6)}"
  end

  defp format_duration(seconds) when is_number(seconds) do
    total_minutes = trunc(seconds / 60)
    hours = div(total_minutes, 60)
    remaining_minutes = rem(total_minutes, 60)

    cond do
      hours > 0 -> "#{hours}h #{remaining_minutes}min"
      true -> "#{total_minutes}min"
    end
  end

  defp format_duration(_), do: "N/A"

  defp format_distance(km) do
    if km < 1 do
      "#{Float.round(km * 1000, 0)}m"
    else
      "#{Float.round(km, 2)}km"
    end
  end

  defp extract_shape(%{"trip" => %{"legs" => [first_leg | _]}}) do
    Map.get(first_leg, "shape")
  end

  defp extract_shape(_), do: nil

  defp push_shape_update(socket) do
    locations = socket.assigns.locations
    shape = socket.assigns.map_shape

    socket =
      case locations do
        [{s_lat, s_lon}, {e_lat, e_lon} | _] ->
          push_event(socket, "update_map", %{
            start: %{lat: s_lat, lon: s_lon},
            end: %{lat: e_lat, lon: e_lon},
            shape: shape
          })

        _ ->
          socket
      end

    socket
  end
end
