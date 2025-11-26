defmodule MegamoveWeb.HomeComponents.TransportRequest do
  use MegamoveWeb, :live_component

  alias MegamoveWeb.TransportRequestComponent
  alias MegamoveWeb.TransportRequestCardComponent
  alias Megamove.TransportRequests

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      socket
      |> assign_new(:show_form, fn -> false end)

    socket =
      case Map.get(assigns, :current_scope) do
        %{user: _} = current_scope ->
          requests = TransportRequests.list_user_transport_requests(current_scope)
          requests_with_id = Enum.map(requests, &ensure_stream_id/1)

          socket
          |> assign(:requests_empty?, requests_with_id == [])
          |> stream(:requests, requests_with_id, reset: true)

        _ ->
          socket
          |> assign(:requests_empty?, true)
          |> stream(:requests, [], reset: true)
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="rounded-xl border border-gray-200 bg-white/70 dark:bg-base-200 p-6 shadow-sm space-y-6">
      <div>
        <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
          Démonstration - Demande de transport
        </h2>
        <p class="mt-2 text-gray-600 dark:text-gray-300">
          Utilisez ce formulaire pour créer une demande de transport. Saisissez les adresses de départ et d'arrivée, et visualisez le trajet sur la carte.
        </p>

        <div :if={!@show_form} class="mt-4">
          <button
            type="button"
            phx-click="toggle_form"
            phx-target={@myself}
            class="inline-flex items-center gap-2 px-4 py-2 border border-blue-600 bg-transparent text-blue-600 rounded-md hover:bg-blue-50 transition-all font-medium"
          >
            <.icon name="hero-plus" class="h-5 w-5" /> Nouvelle demande
          </button>
        </div>

        <div :if={@show_form} class="mt-4">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Nouvelle demande de transport
            </h3>
            <button
              type="button"
              phx-click="toggle_form"
              phx-target={@myself}
              class="px-3 py-1.5 text-sm text-gray-600 hover:text-gray-900 border border-gray-300 rounded-md hover:bg-gray-50 transition-all"
            >
              Annuler
            </button>
          </div>
          <.live_component
            module={TransportRequestComponent}
            id="transport-request-demo"
          />
        </div>
      </div>

      <div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Mes demandes</h3>
        <div
          :if={@requests_empty?}
          class="mt-2 text-sm text-gray-600 dark:text-gray-300"
        >
          Aucune demande pour le moment.
        </div>
        <div id="requests" phx-update="stream" class="mt-4 grid grid-cols-1 gap-4">
          <div :for={{id, req} <- @streams.requests} id={id}>
            <.live_component
              module={TransportRequestCardComponent}
              id={"transport-request-card-" <> Integer.to_string(req.request.id)}
              request={req}
              pickup_place={req.pickup_place}
              dropoff_place={req.dropoff_place}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  defp ensure_stream_id(%{id: _} = item), do: item

  defp ensure_stream_id(%{request: %{id: id}} = item) when is_integer(id),
    do: Map.put(item, :id, "tr-" <> Integer.to_string(id))
end
