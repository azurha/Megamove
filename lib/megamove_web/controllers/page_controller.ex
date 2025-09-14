defmodule MegamoveWeb.PageController do
  use MegamoveWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
