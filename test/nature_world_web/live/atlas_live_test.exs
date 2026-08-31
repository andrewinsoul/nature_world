defmodule NatureWorldWeb.AtlasLiveTest do
  use NatureWorldWeb.ConnCase

  import Phoenix.LiveViewTest

  test "guided tutorial starts on first visit and advances on citizen selection", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#guided-tutorial[data-step=\"welcome\"]")

    render_click(element(view, "#citizen-1-1"))

    assert has_element?(view, "#guided-tutorial[data-step=\"message_passing\"]")
  end

  test "guided tutorial can be dismissed", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    render_click(element(view, "#guided-tutorial-skip"))

    refute has_element?(view, "#guided-tutorial")
  end

  test "citizen clicks still work after the tutorial auto-clears", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    render_click(element(view, "#guided-tutorial-next"))
    render_click(element(view, "#guided-tutorial-next"))
    render_click(element(view, "#guided-tutorial-next"))

    state = :sys.get_state(view.pid)
    send(view.pid, {:clear_tutorial, state.socket.assigns.tutorial.ref})
    _ = :sys.get_state(view.pid)

    render_click(element(view, "#citizen-1-1"))

    assert has_element?(view, "#citizen-1-1")
  end
end
