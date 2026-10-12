defmodule DailyLogosWeb.Plugs.LocaleTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias DailyLogosWeb.Plugs.SetLocale

  test "sets locale from a supported path prefix ahead of a conflicting session locale" do
    conn =
      conn(:get, "/it/about")
      |> init_test_session(%{locale: "en"})
      |> Map.put(:path_params, %{"locale_prefix" => "it"})

    conn = SetLocale.call(conn, SetLocale.init([]))

    assert conn.assigns.locale == "it"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "it"
    refute conn.halted
  end

  test "session locale overrides the Accept-Language header" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "it-IT,it;q=0.9")
      |> init_test_session(%{locale: "en"})

    conn = SetLocale.call(conn, SetLocale.init([]))

    assert conn.assigns.locale == "en"
  end

  test "uses the Accept-Language header when the session has no locale" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "it-IT,it;q=0.9,en-US;q=0.8")
      |> init_test_session(%{})

    conn = SetLocale.call(conn, SetLocale.init([]))

    assert conn.assigns.locale == "it"
  end

  test "marks an unsupported path prefix and falls back to the session locale" do
    conn =
      conn(:get, "/fr/about")
      |> init_test_session(%{locale: "it"})
      |> Map.put(:path_params, %{"locale_prefix" => "fr"})

    conn = SetLocale.call(conn, SetLocale.init([]))

    assert conn.assigns.locale == "it"
    assert conn.assigns.invalid_locale_prefix
    refute conn.halted
  end

  test "falls back to the default locale when no supported locale is detected" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "fr-FR,fr;q=0.9")
      |> init_test_session(%{})

    conn = SetLocale.call(conn, SetLocale.init([]))

    assert conn.assigns.locale == "en"
    assert Gettext.get_locale(DailyLogosWeb.Gettext) == "en"
  end

  test "does not redirect non-GET requests" do
    conn =
      conn(:post, "/users/register")
      |> init_test_session(%{locale: "it"})

    conn = SetLocale.call(conn, SetLocale.init([]))

    refute conn.halted
    assert conn.assigns.locale == "it"
  end
end
