defmodule MegamoveWeb.HomeLiveTest do
  use MegamoveWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias Megamove.Repo
  alias Megamove.TransportRequests.TransportRequest
  alias Megamove.TransportRequests.TransportRequestStop

  describe "home (non connecté)" do
    test "affiche le composant Default", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "img[alt='MegaMove Logo']")
      assert has_element?(view, "a[href='/shipments/new']")
      assert has_element?(view, "span", "Comment ça marche")
    end
  end

  describe "home (connecté)" do
    setup :register_and_log_in_user

    test "affiche le menu et 'Demande de transport' sur /", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "button", "Demande de transport")
      assert has_element?(view, "h2", "Demande de transport")
    end

    test "/logiciel accessible et affiche Demande de transport", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/logiciel")

      assert has_element?(view, "button", "Demande de transport")
      assert has_element?(view, "h2", "Demande de transport")
    end
  end

  describe "création de demande (connecté)" do
    setup :register_and_log_in_user

    test "crée une demande minimale avec 2 arrêts", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      send(
        view.pid,
        {:address_selected,
         %{id: "transport-request-demo-departure", label: "Paris", lat: 48.8566, lon: 2.3522}}
      )

      send(
        view.pid,
        {:address_selected,
         %{id: "transport-request-demo-arrival", label: "Lyon", lat: 45.764, lon: 4.8357}}
      )

      assert render_click(element(view, "#transport-request-demo-create-transport-request")) =~
               "Demande de transport créée."

      assert Repo.aggregate(TransportRequest, :count) == 1
      assert Repo.aggregate(TransportRequestStop, :count) == 2
    end
  end

  describe "liste des demandes (connecté)" do
    setup :register_and_log_in_user

    test "affiche la section Mes demandes vide puis listée après création", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "h3", "Mes demandes")
      assert has_element?(view, "div", "Aucune demande pour le moment.")

      send(
        view.pid,
        {:address_selected,
         %{id: "transport-request-demo-departure", label: "Paris", lat: 48.8566, lon: 2.3522}}
      )

      send(
        view.pid,
        {:address_selected,
         %{id: "transport-request-demo-arrival", label: "Lyon", lat: 45.764, lon: 4.8357}}
      )

      assert render_click(element(view, "#transport-request-demo-create-transport-request")) =~
               "Demande de transport créée."

      # Re-monte la page pour recharger la liste depuis la DB
      {:ok, view2, _html2} = live(conn, ~p"/")

      assert has_element?(view2, "h3", "Mes demandes")
      assert has_element?(view2, "a", "Voir")
    end
  end
end
