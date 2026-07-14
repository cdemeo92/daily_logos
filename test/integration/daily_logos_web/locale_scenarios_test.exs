defmodule DailyLogosWeb.LocaleIntegrationTest do
  use DailyLogosWeb.ConnCase, async: true

  import Plug.Conn

  test "english browser first access lands on /", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "en-US,en;q=0.9")
      |> get("/")

    assert conn.status == 200
    assert conn.assigns.locale == "en"
  end

  test "italian browser first access redirects to /it", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "it-IT,it;q=0.9")
      |> get("/")

    assert redirected_to(conn) == "/it"
  end

  test "links from / (english) respect locale", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "en-US,en;q=0.9")
      |> get("/")

    assert conn.assigns.locale == "en"
  end

  test "links from /it (italian) respect locale", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "it-IT,it;q=0.9")
      |> get("/it")

    assert conn.assigns.locale == "it"
  end

  test "english session switches to italian", %{conn: conn} do
    conn1 =
      conn
      |> init_test_session(%{locale: "en"})
      |> post("/locale/it", %{"locale" => "it"})

    assert redirected_to(conn1) == "/it"
    assert get_session(conn1, :locale) == "it"
  end

  test "italian locale persists in subsequent request", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{locale: "it"})
      |> get("/")

    assert conn.assigns.locale == "it"
  end

  test "italian session switches to english", %{conn: conn} do
    conn1 =
      conn
      |> init_test_session(%{locale: "it"})
      |> post("/locale/en", %{"locale" => "en"})

    assert redirected_to(conn1) == "/"
    assert get_session(conn1, :locale) == "en"
  end

  test "english locale persists in subsequent request", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{locale: "en"})
      |> get("/")

    assert conn.assigns.locale == "en"
  end

  test "toggle from /it/about english redirects with referer stripping", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{locale: "it"})
      |> put_req_header("referer", "/it/about")
      |> post("/locale/en", %{"locale" => "en"})

    assert redirected_to(conn) == "/about"
    assert get_session(conn, :locale) == "en"
  end

  test "toggle from /about italian redirects with referer prefixing", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{locale: "en"})
      |> put_req_header("referer", "/about")
      |> post("/locale/it", %{"locale" => "it"})

    assert redirected_to(conn) == "/it/about"
    assert get_session(conn, :locale) == "it"
  end
end
