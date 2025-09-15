defmodule MegamoveWeb.AddressDemoLive do
  @moduledoc """
  Démo du composant d'autocomplétion d'adresse.

  Affiche un composant d'autocomplétion et, en dessous, les coordonnées
  de l'adresse sélectionnée.
  """

  use MegamoveWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Démo Autocomplétion d'adresse")
     |> assign(:selected, nil)}
  end

  @impl true
  def handle_info({:address_selected, {label, lat, lon}}, socket) do
    {:noreply, assign(socket, :selected, %{label: label, lat: lat, lon: lon})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto p-6 space-y-6">
        <h1 class="text-2xl font-semibold text-gray-900">Démo Autocomplétion d'adresse</h1>

        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">Adresse</label>
          <.live_component
            module={MegamoveWeb.AddressAutocompleteComponent}
            id="address-autocomplete"
            placeholder="Saisissez une adresse (ex: 10 rue...)"
          />
        </div>

        <div class="bg-white rounded-lg border border-gray-200 p-4">
          <h2 class="text-sm font-medium text-gray-700 mb-2">Adresse sélectionnée</h2>
          <div :if={@selected} class="text-gray-900 space-y-1">
            <div class="text-sm">{@selected.label}</div>
            <div class="text-xs text-gray-600">
              Lat: {Float.round(@selected.lat, 6)} — Lon: {Float.round(@selected.lon, 6)}
            </div>
          </div>
          <div :if={!@selected} class="text-sm text-gray-500">Aucune adresse sélectionnée</div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
