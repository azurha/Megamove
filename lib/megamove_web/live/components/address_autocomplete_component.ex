defmodule MegamoveWeb.AddressAutocompleteComponent do
  @moduledoc """
  Composant LiveComponent d'autocomplétion d'adresse basé sur Nominatim.

  Expose un champ texte; en tapant, des suggestions apparaissent.
  Lors de la sélection d'une suggestion, déclenche un événement `address_selected`
  vers le parent avec `%{"label" => display_name, "lat" => lat, "lon" => lon}`.
  """

  use MegamoveWeb, :live_component

  alias Megamove.NominatimService

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:suggestions, [])
     |> assign(:open, false)
     |> assign(:loading, false)
     |> assign(:error, nil)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative" id={@id}>
      <.form for={%{}} as={:ac} id={@id <> "-form"} phx-change="search" phx-target={@myself}>
        <.input
          type="textarea"
          name="q"
          value={@query}
          placeholder={@placeholder || "Saisissez une adresse"}
          phx-debounce="300"
          rows="2"
          class="w-full resize-none leading-tight bg-white border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
      </.form>

      <div
        :if={@open}
        class="absolute z-10 mt-1 w-full bg-white border border-gray-200 rounded-md shadow-lg max-h-64 overflow-auto"
      >
        <div :if={@loading} class="p-3 text-sm text-gray-500">Recherche…</div>
        <div :if={!@loading and @error} class="p-3 text-sm text-red-600">{@error}</div>
        <ul
          :if={!@loading and is_list(@suggestions) and @suggestions != []}
          class="divide-y divide-gray-100"
        >
          <li
            :for={s <- @suggestions}
            class="px-3 py-2 cursor-pointer hover:bg-gray-50"
            phx-click="pick"
            phx-value-label={s.display_name}
            phx-value-lat={s.lat}
            phx-value-lon={s.lon}
            phx-target={@myself}
          >
            <div class="text-sm text-gray-900 truncate">{s.display_name}</div>
          </li>
        </ul>
        <div :if={!@loading and @suggestions == [] and @query != ""} class="p-3 text-sm text-gray-500">
          Aucun résultat
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("search", params, socket) do
    query = get_in(params, ["ac", "q"]) || Map.get(params, "q", "")
    # Nettoie la requête pour Nominatim (les retours à la ligne sont remplacés par des espaces)
    sanitized_query =
      query
      |> String.replace("\n", " ")
      |> String.replace(~r/\s+/, " ")

    if String.trim(query) == "" do
      {:noreply,
       socket
       |> assign(:query, "")
       |> assign(:suggestions, [])
       |> assign(:open, false)
       |> assign(:loading, false)
       |> assign(:error, nil)}
    else
      # Exécute la recherche immédiatement (debounced côté client)
      case NominatimService.search(sanitized_query, limit: 8, language: "fr") do
        {:ok, suggestions} ->
          {:noreply,
           socket
           |> assign(:query, query)
           |> assign(:suggestions, suggestions)
           |> assign(:loading, false)
           |> assign(:open, true)
           |> assign(:error, nil)}

        {:error, reason} ->
          {:noreply,
           socket
           |> assign(:query, query)
           |> assign(:suggestions, [])
           |> assign(:loading, false)
           |> assign(:open, true)
           |> assign(:error, format_error(reason))}
      end
    end
  end

  @impl true
  def handle_event("pick", %{"label" => label, "lat" => lat, "lon" => lon}, socket) do
    latf = to_float(lat)
    lonf = to_float(lon)

    # Notifie directement le parent (LiveView) en précisant la source (id du composant)
    send(self(), {:address_selected, %{id: socket.assigns.id, label: label, lat: latf, lon: lonf}})

    {:noreply,
     socket
     |> assign(:query, format_display(label))
     |> assign(:suggestions, [])
     |> assign(:open, false)
     |> assign(:loading, false)
     |> assign(:error, nil)}
  end

  # Pas d'handle_info ici: la recherche s'effectue directement dans handle_event/3

  # Les événements sont directement gérés par le parent via handle_info/2

  defp to_float(v) when is_float(v), do: v
  defp to_float(v) when is_integer(v), do: v / 1

  defp to_float(v) when is_binary(v) do
    case Float.parse(v) do
      {f, _} -> f
      :error -> 0.0
    end
  end

  defp format_error({:http_error, status, _body}), do: "Erreur HTTP #{status}"
  defp format_error(other), do: "Erreur: #{inspect(other)}"

  defp format_display(label) when is_binary(label) do
    parts =
      label
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    line1 = Enum.at(parts, 0, label)

    postal_index = Enum.find_index(parts, fn p -> Regex.match?(~r/^\d{4,5}$/u, p) end)

    line2 =
      if postal_index do
        postal = Enum.at(parts, postal_index)
        city = Enum.at(parts, postal_index - 1) || Enum.at(parts, postal_index + 1)
        if city, do: postal <> " " <> city, else: postal
      else
        parts
        |> Enum.drop(1)
        |> Enum.take(2)
        |> Enum.join(", ")
      end

    line1 <> "\n" <> line2
  end
end
