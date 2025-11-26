defmodule MegamoveWeb.TransportRequestQuoteInteractionComponent do
  @moduledoc """
  Composant LiveView pour afficher les interactions entre une demande de transport
  et la réponse d'un transporteur, avec gestion de la conversation par messages.
  """

  use MegamoveWeb, :live_component

  alias Megamove.Messages

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:message_form, to_form(%{"content" => ""}))
     |> assign(:new_message_content, "")}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> load_messages()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md border border-gray-200 p-6 space-y-6">
      <%!-- Section d'informations de la quote --%>
      <div class="border-b border-gray-200 pb-4">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold text-gray-900">
              Offre de transport
            </h3>
            <p class="text-sm text-gray-600 mt-1">
              Transporteur: {carrier_name(@quote)}
            </p>
          </div>
          <div class="text-right">
            <p class="text-2xl font-bold text-blue-600">
              {format_price(@quote.price_cents, @quote.currency)}
            </p>
            <p class="text-xs text-gray-500 mt-1">
              Statut: {status_label(@quote.status)}
            </p>
          </div>
        </div>
      </div>

      <%!-- Zone de conversation --%>
      <div class="space-y-4">
        <h4 class="text-md font-semibold text-gray-900">Conversation</h4>
        <div
          id={"messages-#{@id}"}
          class="bg-gray-50 rounded-lg p-4 h-96 overflow-y-auto space-y-3"
        >
          <div :for={message <- @messages} class={["flex", message_class(message, @current_scope)]}>
            <div class={["rounded-lg px-4 py-2 max-w-md", message_bubble_class(message, @current_scope)]}>
              <div class="text-xs text-gray-500 mb-1">
                {sender_name(message, @current_scope)} • {format_datetime(message.inserted_at)}
              </div>
              <div class="text-sm text-gray-900 whitespace-pre-wrap">
                {message.content}
              </div>
            </div>
          </div>
          <div :if={@messages == []} class="text-center text-gray-500 py-8">
            Aucun message pour le moment. Commencez la conversation !
          </div>
        </div>

        <%!-- Formulaire d'envoi de message --%>
        <.form
          for={@message_form}
          id={"message-form-#{@id}"}
          phx-submit="send_message"
          phx-target={@myself}
          class="flex gap-2"
        >
          <.input
            field={@message_form[:content]}
            type="textarea"
            placeholder="Tapez votre message..."
            rows="2"
            class="flex-1"
          />
          <button
            type="submit"
            class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <.icon name="hero-paper-airplane" class="h-5 w-5" />
          </button>
        </.form>
      </div>

      <%!-- Bouton Booker et payer --%>
      <div class="border-t border-gray-200 pt-4">
        <button
          :if={can_book?(@quote)}
          phx-click="book_quote"
          phx-target={@myself}
          class="w-full px-4 py-3 bg-green-600 text-white rounded-md hover:bg-green-700 transition-all font-semibold"
        >
          <.icon name="hero-credit-card" class="h-5 w-5 inline mr-2" />
          Booker et payer
        </button>
        <p :if={!can_book?(@quote)} class="text-sm text-gray-500 text-center">
          {booking_message(@quote)}
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) do
    if String.trim(content) == "" do
      {:noreply, socket}
    else
      case Messages.create_message(socket.assigns.current_scope, %{
             "transport_request_id" => socket.assigns.transport_request.id,
             "quote_id" => socket.assigns.quote.id,
             "content" => String.trim(content)
           }) do
        {:ok, _message} ->
          socket =
            socket
            |> assign(:message_form, to_form(%{"content" => ""}))
            |> load_messages()

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("book_quote", _params, socket) do
    send(self(), {:book_quote, socket.assigns.quote.id})
    {:noreply, socket}
  end

  defp load_messages(socket) do
    messages =
      if socket.assigns[:quote] && socket.assigns.quote.id do
        Messages.list_messages_for_quote(socket.assigns.quote.id)
      else
        []
      end

    assign(socket, :messages, messages)
  end

  defp carrier_name(%{carrier: %{legal_name: name}}) when is_binary(name), do: name
  defp carrier_name(_), do: "Transporteur inconnu"

  defp format_price(price_cents, currency) when is_integer(price_cents) do
    price = price_cents / 100
    :erlang.float_to_binary(price, decimals: 2) <> " " <> (currency || "EUR")
  end

  defp format_price(_, _), do: "—"

  defp status_label(:proposed), do: "Proposé"
  defp status_label(:withdrawn), do: "Retiré"
  defp status_label(:accepted), do: "Accepté"
  defp status_label(:expired), do: "Expiré"
  defp status_label(:rejected), do: "Rejeté"
  defp status_label(_), do: "Inconnu"

  defp message_class(message, current_scope) do
    if message.sender_user_id == current_scope.user.id do
      "justify-end"
    else
      "justify-start"
    end
  end

  defp message_bubble_class(message, current_scope) do
    if message.sender_user_id == current_scope.user.id do
      "bg-blue-600 text-white"
    else
      "bg-white text-gray-900 border border-gray-200"
    end
  end

  defp sender_name(message, current_scope) do
    if message.sender_user_id == current_scope.user.id do
      "Vous"
    else
      message.sender_user.email || "Utilisateur"
    end
  end

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%d/%m/%Y %H:%M")
  end

  defp format_datetime(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%d/%m/%Y %H:%M")
  end

  defp format_datetime(_), do: "—"

  defp can_book?(%{status: :accepted}), do: true
  defp can_book?(_), do: false

  defp booking_message(%{status: :proposed}), do: "En attente d'acceptation de l'offre"
  defp booking_message(%{status: :rejected}), do: "Cette offre a été rejetée"
  defp booking_message(%{status: :expired}), do: "Cette offre a expiré"
  defp booking_message(%{status: :withdrawn}), do: "Cette offre a été retirée"
  defp booking_message(_), do: "Impossible de réserver cette offre"
end
