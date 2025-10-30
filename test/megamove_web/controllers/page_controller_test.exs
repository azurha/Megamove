defmodule MegamoveWeb.PageControllerTest do
  use MegamoveWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "MegaMove"
  end
end
