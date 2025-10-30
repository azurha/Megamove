defmodule MegamoveWeb.HomeComponents.TransportRequest do
  use MegamoveWeb, :live_component

  alias MegamoveWeb.TransportRequestComponent

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="rounded-xl border border-gray-200 bg-white/70 dark:bg-base-200 p-6 shadow-sm">
      <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">Démonstration - Demande de Transport</h2>
      <p class="mt-2 text-gray-600 dark:text-gray-300">
        Utilisez ce formulaire pour créer une demande de transport. Saisissez les adresses de départ et d'arrivée, et visualisez le trajet sur la carte.
      </p>

      <.live_component
        module={TransportRequestComponent}
        id="transport-request-demo"
      />

      <div class="mt-6">
        <button
          id="create-transport-request"
          phx-click="create_transport_request"
          class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Créer la demande
        </button>
      </div>
    </div>
    """
  end
end
