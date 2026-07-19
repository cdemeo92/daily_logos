defmodule DailyLogosWeb.Plugs.LocaleTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias DailyLogosWeb.Plugs.Locale

  test "sets locale from path when it is a supported non-default locale" do
    conn =
      conn(:get, "/it/about")
      |> init_test_session(%{})
      |> Map.put(:path_params, %{"locale_prefix" => "it"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.assigns.locale == "it"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "it"
  end

  test "redirects to canonical path when path locale is the default locale" do
    conn =
      conn(:get, "/en/about")
      |> init_test_session(%{})
      |> Map.put(:path_params, %{"locale_prefix" => "en"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/about"]
  end

  test "redirects to root when path locale prefix is the only segment" do
    conn =
      conn(:get, "/en")
      |> init_test_session(%{})
      |> Map.put(:path_params, %{"locale_prefix" => "en"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/"]
  end

  test "redirects to localized path when non-default session locale is present" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "en-US,en;q=0.9")
      |> init_test_session(%{locale: "it"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/it"]
  end

  test "default locale prefix still canonicalizes even when session locale differs" do
    conn =
      conn(:get, "/en/asdf")
      |> init_test_session(%{locale: "it"})
      |> Map.put(:path_params, %{"locale_prefix" => "en"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/asdf"]
  end

  test "preserves query string when redirecting from session locale" do
    conn =
      conn(:get, "/support?utm_source=test")
      |> init_test_session(%{locale: "it"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/it/support?utm_source=test"]
  end

  test "session overrides accept-language header" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "it-IT,it;q=0.9")
      |> init_test_session(%{locale: "en"})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.assigns.locale == "en"
  end

  test "detects locale from accept-language header when no session" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "it-IT,it;q=0.9,en-US;q=0.8")
      |> init_test_session(%{})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/it"]
  end

  test "redirects to localized path when no session and non-default header" do
    conn =
      conn(:get, "/about")
      |> put_req_header("accept-language", "it-IT,it;q=0.9")
      |> init_test_session(%{})

    conn = Locale.call(conn, Locale.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/it/about"]
  end

  test "does not redirect when session is present, even if header differs" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "it-IT,it;q=0.9")
      |> init_test_session(%{locale: "en"})

    conn = Locale.call(conn, Locale.init([]))

    assert not conn.halted
    assert conn.assigns.locale == "en"
  end

  test "falls back to default locale when no supported locale is detected" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "fr-FR,fr;q=0.9")
      |> init_test_session(%{})

    conn = Locale.call(conn, Locale.init([]))

    assert not conn.halted
    assert conn.assigns.locale == "en"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "en"
  end
end
