defmodule NatureWorldWeb.PageController do
  use NatureWorldWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
