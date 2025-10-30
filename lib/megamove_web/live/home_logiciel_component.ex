defmodule MegamoveWeb.HomeComponents.Logiciel do
  use MegamoveWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="border-b bg-white/70 dark:bg-base-200">
        <div class="mx-auto max-w-6xl px-4">
          <div class="flex gap-2 overflow-x-auto py-3">
            <button
              phx-click="select_tab"
              phx-value-tab="demande_transport"
              class={[
                "px-3 py-2 rounded-md text-sm font-medium transition-all",
                @active_tab == "demande_transport" && "bg-blue-600 text-white",
                @active_tab != "demande_transport" &&
                  "bg-gray-100 hover:bg-gray-200 dark:bg-base-300 dark:hover:bg-base-200"
              ]}
            >
              Demande de transport
            </button>
          </div>
        </div>
      </div>

      <div class="mx-auto max-w-6xl px-4 py-6">
        <%= if @active_tab == "demande_transport" do %>
          <.live_component
            module={MegamoveWeb.HomeComponents.TransportRequest}
            id="transport-request"
            current_scope={@current_scope}
          />
        <% end %>
      </div>
    </div>
    """
  end
end
