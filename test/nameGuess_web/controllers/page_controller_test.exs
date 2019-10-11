defmodule NameGuessWeb.PageControllerTest do
  use NameGuessWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Do you know the name of your"
  end

  test "GET /highscores", %{conn: conn} do
    conn = get(conn, "/highscores")
    assert html_response(conn, 200) =~ "High Scores"
  end

  test "GET /stats", %{conn: conn} do
    conn = get(conn, "/stats")
    assert html_response(conn, 200) =~ "Stats"
  end
end
