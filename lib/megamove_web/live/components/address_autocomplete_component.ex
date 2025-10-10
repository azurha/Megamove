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
    <div class="relative" id={@id} phx-hook="AddressAutocomplete">
      <div class="group relative">
        <div class="pointer-events-none absolute -inset-[1.5px] rounded-2xl bg-gradient-to-r from-blue-100 via-teal-100 to-blue-100 opacity-0 transition-all duration-300 group-focus-within:opacity-100 group-hover:opacity-70">
        </div>
        <div class="relative overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition-all duration-300 group-hover:shadow-md group-focus-within:border-blue-400 group-focus-within:shadow-xl">
          <div class="flex flex-col gap-3 p-4 sm:p-5">
            <.form
              for={%{}}
              as={:ac}
              id={@id <> "-form"}
              phx-change="search"
              phx-target={@myself}
              class="rounded-2xl bg-gray-50/70 px-3.5 py-2 transition focus-within:bg-white focus-within:shadow-inner"
            >
              <.input
                type="textarea"
                name="q"
                value={@query}
                placeholder={@placeholder || "Saisissez une adresse"}
                phx-debounce="300"
                rows="2"
                phx-hook="AutosizeTextarea"
                id={@id <> "-textarea"}
                class="w-full resize-none border-0 bg-transparent p-0 text-base leading-tight text-gray-900 placeholder:text-gray-400 focus:outline-none focus:ring-0 sm:text-lg"
              />
            </.form>

            <div
              :if={@loading or (is_list(@suggestions) and @suggestions != []) or @error}
              class="flex flex-col items-end gap-3"
            >
              <span
                :if={@loading}
                class="inline-flex items-center gap-2 rounded-full bg-blue-50 px-3 py-1 text-xs font-medium text-blue-600"
              >
                <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin" /> Recherche…
              </span>
              <span
                :if={!@loading and is_list(@suggestions) and @suggestions != []}
                class="inline-flex items-center gap-2 rounded-full bg-emerald-50 px-3 py-1 text-xs font-medium text-emerald-600"
              >
                <.icon name="hero-sparkles" class="h-4 w-4" />
                {Enum.count(@suggestions)} suggestions
              </span>
              <span
                :if={!@loading and @error}
                class="inline-flex items-center gap-2 rounded-full bg-red-50 px-3 py-1 text-xs font-medium text-red-600"
              >
                <.icon name="hero-exclamation-triangle" class="h-4 w-4" /> Erreur
              </span>
            </div>
          </div>
        </div>
      </div>

      <div
        :if={@open}
        class="absolute left-0 right-0 top-[calc(100%+0.75rem)] z-20 overflow-hidden rounded-2xl border border-gray-200 bg-white/95 shadow-[0_28px_60px_rgba(15,23,42,0.18)] backdrop-blur"
      >
        <div
          :if={@loading}
          class="flex items-center gap-2 px-5 py-4 text-sm font-medium text-blue-600"
        >
          <.icon name="hero-arrow-path" class="h-4 w-4 animate-spin" /> Recherche en cours…
        </div>
        <div
          :if={!@loading and @error}
          class="flex items-center gap-2 px-5 py-4 text-sm font-medium text-red-600"
        >
          <.icon name="hero-exclamation-triangle" class="h-4 w-4" />
          {@error}
        </div>
        <div
          :if={!@loading and is_list(@suggestions) and @suggestions != []}
          class="max-h-72 overflow-y-auto"
        >
          <ul class="divide-y divide-gray-100">
            <li
              :for={s <- @suggestions}
              class="cursor-pointer px-5 py-3 transition hover:bg-blue-50/80"
              phx-click="pick"
              phx-value-label={s.display_name}
              phx-value-lat={s.lat}
              phx-value-lon={s.lon}
              phx-target={@myself}
            >
              <div class="text-sm font-medium text-gray-900">
                {s.display_name}
              </div>
            </li>
          </ul>
        </div>
        <div
          :if={!@loading and @suggestions == [] and @query != ""}
          class="px-5 py-4 text-sm text-gray-500"
        >
          Aucun résultat pour cette recherche
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
  def handle_event("dismiss", _params, socket) do
    {:noreply,
     socket
     |> assign(:open, false)
     |> assign(:loading, false)
     |> assign(:suggestions, [])
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("pick", %{"label" => label, "lat" => lat, "lon" => lon}, socket) do
    latf = to_float(lat)
    lonf = to_float(lon)

    # Notifie directement le parent (LiveView) en précisant la source (id du composant)
    send(
      self(),
      {:address_selected, %{id: socket.assigns.id, label: label, lat: latf, lon: lonf}}
    )

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
