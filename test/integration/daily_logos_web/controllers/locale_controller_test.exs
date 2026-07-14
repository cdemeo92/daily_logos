defmodule DailyLogosWeb.LocaleControllerTest do
  use DailyLogosWeb.ConnCase

  for locale <- ["en", "it"] do
    test "POST /locale/#{locale} persists locale in session", %{conn: conn} do
      conn = post(conn, ~p"/locale/#{unquote(locale)}")
      assert get_session(conn, :locale) == unquote(locale)
    end
  end

  test "POST /locale/en redirects to /", %{conn: conn} do
    conn = post(conn, ~p"/locale/en")
    assert redirected_to(conn) == "/"
  end

  test "POST /locale/it redirects to /it", %{conn: conn} do
    conn = post(conn, ~p"/locale/it")
    assert redirected_to(conn) == "/it"
  end

  test "POST /locale/unsupported does not change locale in the session", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})
      |> put_session(:locale, "it")
      |> post(~p"/locale/unsupported-locale")

    assert redirected_to(conn) == "/"
    assert get_session(conn, :locale) == "it"
  end

  test "POST /locale/it with referer redirects to localized referer", %{conn: conn} do
    conn =
      conn
      |> put_req_header("referer", "/about")
      |> post(~p"/locale/it")

    assert redirected_to(conn) == "/it/about"
  end

  test "POST /locale/en with localized referer redirects to canonical referer", %{conn: conn} do
    conn =
      conn
      |> put_req_header("referer", "/it/about")
      |> post(~p"/locale/en")

    assert redirected_to(conn) == "/about"
  end
end
