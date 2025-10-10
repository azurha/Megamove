defmodule MegamoveWeb.TransportRequestDemoLive do
  @moduledoc """
  Page de démonstration pour le composant de demande de transport.
  """

  use MegamoveWeb, :live_view

  alias MegamoveWeb.TransportRequestComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto px-4 py-8">
        <div class="max-w-6xl mx-auto">
          <h1 class="text-3xl font-bold text-gray-900 mb-8">
            Démonstration - Demande de Transport
          </h1>

          <p class="text-gray-600 mb-8">
            Utilisez ce formulaire pour créer une demande de transport.
            Saisissez les adresses de départ et d'arrivée, et visualisez le trajet sur la carte.
          </p>

          <.live_component
            module={TransportRequestComponent}
            id="transport-request-demo"
          />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_info({:address_selected, %{id: id, label: label, lat: lat, lon: lon}}, socket) do
    which =
      cond do
        String.ends_with?(id, "-departure") -> :departure
        String.ends_with?(id, "-arrival") -> :arrival
        true -> :unknown
      end

    payload =
      case which do
        :departure -> %{departure: %{label: label, lat: lat, lon: lon}}
        :arrival -> %{arrival: %{label: label, lat: lat, lon: lon}}
        :unknown -> %{}
      end

    if payload != %{} do
      send_update(
        TransportRequestComponent,
        Keyword.merge([id: "transport-request-demo"], Map.to_list(payload))
      )
    end

    {:noreply, socket}
  end
end
