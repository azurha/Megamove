defmodule MegamoveWeb.TransportRequestCardComponent do
  use MegamoveWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :offers_expanded, false)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="rounded-xl border border-gray-200 bg-white/70 dark:bg-base-200 p-4 shadow-sm">
      <div class="flex items-start justify-between gap-4">
        <div class="space-y-1">
          <div class="text-sm text-gray-600 dark:text-gray-300">Départ</div>
          <div class="font-medium text-gray-900 dark:text-gray-100">
            {pickup_label(@pickup_place)}
          </div>
        </div>
        <div class="self-stretch w-px bg-gray-200"></div>
        <div class="space-y-1">
          <div class="text-sm text-gray-600 dark:text-gray-300">Arrivée</div>
          <div class="font-medium text-gray-900 dark:text-gray-100">
            {pickup_label(@dropoff_place)}
          </div>
        </div>
        <div class="ml-auto text-right space-y-1">
          <div class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-800 dark:bg-base-300 dark:text-gray-100">
            {status_label(@request.request.status)}
          </div>
          <div class="text-xs text-gray-500">
            Créée le {format_date(@request.request.inserted_at)}
          </div>
          <div
            :if={@request.request.distance_km}
            class="text-sm text-gray-700 dark:text-gray-300 mt-1"
          >
            Distance: {format_distance(@request.request.distance_km)}
          </div>
          <div
            :if={@request.request.distance_km}
            class="text-sm font-semibold text-gray-900 dark:text-gray-100"
          >
            Prix estimé: {format_price(@request.request.distance_km)}
          </div>
          <div class="flex gap-2 mt-2">
            <button
              type="button"
              phx-click="toggle_offers"
              phx-target={@myself}
              class="inline-flex items-center gap-1 rounded-md bg-gray-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-gray-700 transition-all"
            >
              <.icon
                name={if @offers_expanded, do: "hero-chevron-up", else: "hero-chevron-down"}
                class="h-4 w-4"
              />
              {if @offers_expanded, do: "Masquer", else: "Voir"} les offres
            </button>
            <button
              type="button"
              phx-click="delete_transport_request"
              phx-target={@myself}
              phx-value-id={@request.request.id}
              class="inline-flex items-center gap-1 rounded-md bg-red-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-red-700 transition-all"
            >
              <.icon name="hero-trash" class="h-4 w-4" /> Supprimer
            </button>
          </div>
        </div>
      </div>
      <div :if={@offers_expanded} class="mt-4 pt-4 border-t border-gray-200">
        <%!-- Section des offres - composant à créer plus tard --%>
        <div class="text-sm text-gray-600 dark:text-gray-300">
          Les offres seront affichées ici.
        </div>
      </div>
    </div>
    """
  end

  defp pickup_label(nil), do: "—"
  defp pickup_label(%{name: name}) when is_binary(name) and byte_size(name) > 0, do: name

  defp pickup_label(%{address: address}) when is_binary(address) and byte_size(address) > 0,
    do: address

  defp pickup_label(_), do: "—"

  defp status_label(nil), do: "—"

  defp status_label(:published), do: "Publiée"
  defp status_label(:quoted), do: "Quoted"
  defp status_label(:booked), do: "Booked"
  defp status_label(:completed), do: "Completed"
  defp status_label(:litige), do: "Litige"

  defp status_label(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
  end

  defp format_date(nil), do: "—"
  defp format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d/%m/%Y")
  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%d/%m/%Y")

  defp format_distance(nil), do: "—"

  defp format_distance(%Decimal{} = distance) do
    distance
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
    |> Kernel.<>(" km")
  end

  defp format_distance(distance) when is_number(distance) do
    :erlang.float_to_binary(distance * 1.0, decimals: 2)
    |> Kernel.<>(" km")
  end

  defp format_price(nil), do: "—"

  defp format_price(%Decimal{} = distance_km) do
    price = Decimal.mult(distance_km, Decimal.from_float(1.5))

    price
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
    |> Kernel.<>(" €")
  end

  defp format_price(distance_km) when is_number(distance_km) do
    price = distance_km * 1.5

    :erlang.float_to_binary(price, decimals: 2)
    |> Kernel.<>(" €")
  end

  @impl true
  def handle_event("toggle_offers", _params, socket) do
    {:noreply, assign(socket, :offers_expanded, !socket.assigns.offers_expanded)}
  end

  @impl true
  def handle_event("delete_transport_request", %{"id" => id}, socket) do
    send(self(), {:delete_transport_request, String.to_integer(id)})
    {:noreply, socket}
  end
end
