defmodule DailyLogosWeb.PageControllerTest do
  use DailyLogosWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Daily Logos"
  end

  test "GET /feedback renders page", %{conn: conn} do
    conn = get(conn, ~p"/feedback")
    assert html_response(conn, 200) =~ "feedback-title"
  end

  test "GET /feedback shows placeholder when form url not configured", %{conn: conn} do
    conn = get(conn, ~p"/feedback")
    assert html_response(conn, 200) =~ "feedback-placeholder"
  end

  test "GET /about renders page", %{conn: conn} do
    conn = get(conn, ~p"/about")
    assert html_response(conn, 200) =~ "about-title"
  end

  test "GET /support renders page", %{conn: conn} do
    conn = get(conn, ~p"/support")
    assert html_response(conn, 200) =~ "Daily Logos"
  end
end
