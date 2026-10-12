defmodule DailyLogosWeb.Plugs.LocaleRedirectTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias DailyLogosWeb.Plugs.LocaleRedirect

  test "redirects the default locale prefix to the canonical path" do
    conn =
      conn(:get, "/en/about")
      |> assign(:locale, "en")
      |> Map.put(:path_params, %{"locale_prefix" => "en"})

    conn = LocaleRedirect.call(conn, LocaleRedirect.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/about"]
  end

  test "redirects the default locale prefix root to the canonical root" do
    conn =
      conn(:get, "/en")
      |> assign(:locale, "en")
      |> Map.put(:path_params, %{"locale_prefix" => "en"})

    conn = LocaleRedirect.call(conn, LocaleRedirect.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/"]
  end

  test "canonicalizes a default locale path with repeated slashes" do
    conn =
      conn(:get, "//en/users/settings?ref=test")
      |> assign(:locale, "en")
      |> Map.put(:path_params, %{"locale_prefix" => "en"})

    conn = LocaleRedirect.call(conn, LocaleRedirect.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/users/settings?ref=test"]
  end

  test "redirects canonical paths to the assigned non-default locale" do
    conn = conn(:get, "/about") |> assign(:locale, "it")

    conn = LocaleRedirect.call(conn, LocaleRedirect.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/it/about"]
  end

  test "preserves the query string when redirecting" do
    conn =
      conn(:get, "/about?utm_source=test")
      |> assign(:locale, "it")

    conn = LocaleRedirect.call(conn, LocaleRedirect.init([]))

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/it/about?utm_source=test"]
  end

  test "does not redirect a supported non-default locale path" do
    conn =
      conn(:get, "/it/about")
      |> assign(:locale, "it")
      |> Map.put(:path_params, %{"locale_prefix" => "it"})

    conn = LocaleRedirect.call(conn, LocaleRedirect.init([]))

    refute conn.halted
  end

  test "does not redirect an unsupported locale prefix" do
    conn =
      conn(:get, "/fr/about")
      |> assign(:locale, "it")
      |> assign(:invalid_locale_prefix, true)
      |> Map.put(:path_params, %{"locale_prefix" => "fr"})

    conn = LocaleRedirect.call(conn, LocaleRedirect.init([]))

    refute conn.halted
  end

  test "never redirects non-GET requests" do
    conn = conn(:post, "/users/register") |> assign(:locale, "it")

    conn = LocaleRedirect.call(conn, LocaleRedirect.init([]))

    refute conn.halted
  end
end
