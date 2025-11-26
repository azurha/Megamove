defmodule Megamove.Messages do
  @moduledoc """
  Contexte pour la gestion des messages de conversation.
  """

  import Ecto.Query, warn: false
  alias Megamove.Repo

  alias Megamove.Messages.Message

  @doc """
  Crée un nouveau message.
  """
  @spec create_message(map(), map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def create_message(current_scope, attrs) do
    org_id = current_scope.user.org_id
    user_id = current_scope.user.id

    %Message{}
    |> Message.changeset(
      Map.merge(attrs, %{
        "org_id" => org_id,
        "sender_user_id" => user_id
      })
    )
    |> Repo.insert()
  end

  @doc """
  Liste les messages pour une demande de transport donnée.
  """
  @spec list_messages_for_transport_request(integer()) :: [Message.t()]
  def list_messages_for_transport_request(transport_request_id) do
    from(m in Message,
      where: m.transport_request_id == ^transport_request_id,
      order_by: [asc: m.inserted_at],
      preload: [:sender_user]
    )
    |> Repo.all()
  end

  @doc """
  Liste les messages pour une quote donnée.
  """
  @spec list_messages_for_quote(integer()) :: [Message.t()]
  def list_messages_for_quote(quote_id) do
    from(m in Message,
      where: m.quote_id == ^quote_id,
      order_by: [asc: m.inserted_at],
      preload: [:sender_user]
    )
    |> Repo.all()
  end

  @doc """
  Marque un message comme lu.
  """
  @spec mark_as_read(integer(), map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def mark_as_read(message_id, current_scope) do
    case Repo.get(Message, message_id) do
      nil ->
        {:error, :not_found}

      message ->
        if message.org_id == current_scope.user.org_id do
          message
          |> Message.changeset(%{read_at: DateTime.utc_now()})
          |> Repo.update()
        else
          {:error, :forbidden}
        end
    end
  end
end
