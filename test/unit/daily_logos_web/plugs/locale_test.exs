defmodule DailyLogosWeb.Plugs.LocaleTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias DailyLogosWeb.Plugs.Locale

  test "uses locale from session when present" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "en-US,en;q=0.9")
      |> init_test_session(%{locale: "it"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.assigns.locale == "it"
    assert get_session(conn, :locale) == "it"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "it"
  end

  test "detects locale from accept-language header and persists it in session when session is not set" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "it-IT,it;q=0.9,en-US;q=0.8")
      |> init_test_session(%{})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.assigns.locale == "it"
    assert get_session(conn, :locale) == "it"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "it"
  end

  test "falls back to default locale when header has no supported locale and session is not set" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "fr-FR,fr;q=0.9")
      |> init_test_session(%{})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.assigns.locale == "en"
    assert get_session(conn, :locale) == "en"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "en"
  end

  test "falls back to default when the session locale is not supported" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "en-US,en;q=0.9")
      |> init_test_session(%{locale: "fr"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.assigns.locale == "en"
    assert get_session(conn, :locale) == "en"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "en"
  end

  test "falls back to default when the accept-language header is not supported" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "fr-FR,fr;q=0.9")
      |> init_test_session(%{})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.assigns.locale == "en"
    assert get_session(conn, :locale) == "en"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "en"
  end

  test "detects locale from accept-language header and persists it in session when session is not supported" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "it-IT,it;q=0.9,en-US;q=0.8")
      |> init_test_session(%{locale: "fr"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.assigns.locale == "it"
    assert get_session(conn, :locale) == "it"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "it"
  end
end
