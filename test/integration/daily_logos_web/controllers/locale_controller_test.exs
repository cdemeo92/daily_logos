defmodule DailyLogosWeb.LocaleControllerTest do
  use DailyLogosWeb.ConnCase

  for locale <- ["en", "it"] do
    test "POST /locale/#{locale} persists locale in session", %{conn: conn} do
      conn = post(conn, ~p"/locale/#{unquote(locale)}")

      assert redirected_to(conn) == "/"
      assert get_session(conn, :locale) == unquote(locale)
    end
  end

  test "POST /locale/unsupported does not change locale in the session when already set", %{
    conn: conn
  } do
    conn =
      conn
      |> init_test_session(%{})
      |> put_session(:locale, "it")
      |> post(~p"/locale/unsupported-locale")

    assert redirected_to(conn) == "/"
    assert get_session(conn, :locale) == "it"
  end

  test "POST /locale with referer redirects to referer", %{conn: conn} do
    conn =
      conn
      |> put_req_header("referer", "/some-page")
      |> post(~p"/locale/it")

    assert redirected_to(conn) == "/some-page"
  end
end
