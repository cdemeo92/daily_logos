defmodule DailyLogosWeb.PageControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

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

  test "notifications pages expose indexable localized metadata", %{conn: conn} do
    for {path, title, description} <- [
          {"/notifications", "Daily Stoic Quote Notifications | Daily Logos",
           "Receive daily Stoic quotes by email and build a daily reflection habit with Daily Logos."},
          {"/it/notifications", "Notifiche con citazioni stoiche quotidiane | Daily Logos",
           "Ricevi ogni giorno citazioni stoiche via email e coltiva una riflessione quotidiana con Daily Logos."}
        ] do
      document = conn |> get(path) |> html_response(200) |> LazyHTML.from_document()
      canonical = DailyLogosWeb.Endpoint.url() <> path

      for selector <- [
            "title",
            "meta[name='robots'][content='index,follow']",
            "meta[name='description'][content='#{description}']",
            "meta[property='og:title'][content='#{title}']",
            "meta[property='og:description'][content='#{description}']",
            "meta[property='og:url'][content='#{canonical}']",
            "link[rel='canonical'][href='#{canonical}']",
            "link[hreflang='en'][href='#{DailyLogosWeb.Endpoint.url()}/notifications']",
            "link[hreflang='it'][href='#{DailyLogosWeb.Endpoint.url()}/it/notifications']"
          ] do
        assert document |> LazyHTML.query(selector) |> Enum.any?(), selector
      end

      assert document |> LazyHTML.query("title") |> LazyHTML.text() == title
    end
  end

  test "GET /privacy renders page", %{conn: conn} do
    response = conn |> get("/privacy") |> html_response(200)

    assert response =~ "privacy-title"
    assert response =~ "_daily_logos_key"
    assert response =~ "__phoenix_flash__"
    assert response =~ "_daily_logos_web_user_remember_me"
    assert response =~ "cc_cookie"
    assert response =~ "60 seconds"
    assert response =~ "182 days"
    assert response =~ "_ga_"
    assert response =~ "_gid"
    assert response =~ "_gat"
  end

  test "GET /it renders Italian home", %{conn: conn} do
    conn = get(conn, "/it")
    assert html_response(conn, 200) =~ "Daily Logos"
  end

  test "GET /it/about renders Italian about page", %{conn: conn} do
    conn = get(conn, "/it/about")
    assert html_response(conn, 200) =~ "about-title"
  end

  test "GET /it/feedback renders Italian feedback page", %{conn: conn} do
    conn = get(conn, "/it/feedback")
    assert html_response(conn, 200) =~ "feedback-title"
  end

  test "GET /it/privacy renders Italian privacy page", %{conn: conn} do
    response = conn |> get("/it/privacy") |> html_response(200)

    assert response =~ "privacy-title"
    assert response =~ "_daily_logos_web_user_remember_me"
    assert response =~ "phx:theme"
    assert response =~ "Altri dati memorizzati nel browser"
    assert response =~ "Non è un cookie."
  end

  test "GET /en redirects to /", %{conn: conn} do
    conn = get(conn, "/en")
    assert redirected_to(conn) == "/"
  end

  test "GET /en/about redirects to /about", %{conn: conn} do
    conn = get(conn, "/en/about")
    assert redirected_to(conn) == "/about"
  end

  test "GET /not-exist returns not-found", %{conn: conn} do
    conn = get(conn, "/not-exist")
    assert conn.status == 404
  end

  test "GET /it/not-exist returns not-found", %{conn: conn} do
    conn = get(conn, "/it/not-exist")
    assert conn.status == 404
  end

  test "GET unknown localized path with Italian session returns not-found", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{locale: "it"})
      |> get("/it/9/15/asdf")

    assert conn.status == 404
    assert get_resp_header(conn, "location") == []
  end
end
