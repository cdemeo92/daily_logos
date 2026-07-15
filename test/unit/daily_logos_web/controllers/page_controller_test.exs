defmodule DailyLogosWeb.PageControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  @endpoint DailyLogosWeb.Endpoint

  setup_all do
    Application.ensure_all_started(:plug)

    case Process.whereis(DailyLogosWeb.Endpoint) do
      nil -> start_supervised!(DailyLogosWeb.Endpoint)
      _pid -> :ok
    end

    :ok
  end

  setup do
    {:ok, conn: build_conn()}
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Daily Logos"
  end

  test "GET /feedback renders page", %{conn: conn} do
    conn = get(conn, "/feedback")
    assert html_response(conn, 200) =~ "feedback-title"
  end

  test "GET /feedback shows placeholder when form url not configured", %{conn: conn} do
    conn = get(conn, "/feedback")
    assert html_response(conn, 200) =~ "feedback-placeholder"
  end

  test "GET /about renders page", %{conn: conn} do
    conn = get(conn, "/about")
    assert html_response(conn, 200) =~ "about-title"
  end

  test "GET /support renders page", %{conn: conn} do
    conn = get(conn, "/support")
    assert html_response(conn, 200) =~ "Daily Logos"
  end

  test "GET /support shows placeholder when buy-me-coffe url not configured", %{conn: conn} do
    conn = get(conn, "/support")
    assert html_response(conn, 200) =~ "buy-me-coffee-placeholder"
  end

  test "GET /privacy renders page", %{conn: conn} do
    conn = get(conn, "/privacy")
    assert html_response(conn, 200) =~ "privacy-title"
  end

  test "GET /it renders Italian home", %{conn: conn} do
    conn = get(conn, "/it")
    assert html_response(conn, 200) =~ "Daily Logos"
  end

  test "GET /it/about renders Italian about page", %{conn: conn} do
    conn = get(conn, "/it/about")
    assert html_response(conn, 200) =~ "about-title"
  end

  test "GET /it/support renders Italian support page", %{conn: conn} do
    conn = get(conn, "/it/support")
    assert html_response(conn, 200) =~ "Daily Logos"
  end

  test "GET /it/feedback renders Italian feedback page", %{conn: conn} do
    conn = get(conn, "/it/feedback")
    assert html_response(conn, 200) =~ "feedback-title"
  end

  test "GET /it/privacy renders Italian privacy page", %{conn: conn} do
    conn = get(conn, "/it/privacy")
    assert html_response(conn, 200) =~ "privacy-title"
  end

  test "GET /en redirects to /", %{conn: conn} do
    conn = get(conn, "/en")
    assert redirected_to(conn) == "/"
  end

  test "GET /en/about redirects to /about", %{conn: conn} do
    conn = get(conn, "/en/about")
    assert redirected_to(conn) == "/about"
  end

  test "GET /fr/about redirects to /about", %{conn: conn} do
    conn = get(conn, "/fr/about")
    assert redirected_to(conn) == "/about"
  end
end
