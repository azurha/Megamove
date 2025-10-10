defmodule MegamoveWeb.MapComponent do
  use MegamoveWeb, :live_component

  @moduledoc """
  Composant carte Leaflet réutilisable.

  Attributs:
  - id (obligatoire)
  - markers: liste de %{lat: float, lon: float, label?: String.t, color?: String.t}
  - polylines: liste de %{shape: String.t | [[lat, lon]], color?: String.t, weight?: integer}
  - fit: bool (par défaut true)
  """

  attr :id, :string, required: true
  attr :markers, :list, default: []
  attr :polylines, :list, default: []
  attr :fit, :boolean, default: true
  attr :class, :string, default: "w-full h-80 rounded-md border border-gray-200"

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="Map"
      phx-update="ignore"
      data-markers={Jason.encode!(@markers)}
      data-polylines={Jason.encode!(@polylines)}
      data-fit={@fit}
      class={@class}
    />
    """
  end
end
