defmodule DailyLogosWeb.LocaleControllerUnitTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias DailyLogosWeb.LocaleController

  test "set/2 stores locale en in session and redirects to /" do
    conn =
      conn(:post, "/locale/en")
      |> init_test_session(%{})
      |> LocaleController.set(%{"locale" => "en"})

    assert get_session(conn, :locale) == "en"
    assert get_resp_header(conn, "location") == ["/"]
  end

  test "set/2 stores locale it in session and redirects to /it" do
    conn =
      conn(:post, "/locale/it")
      |> init_test_session(%{})
      |> LocaleController.set(%{"locale" => "it"})

    assert get_session(conn, :locale) == "it"
    assert get_resp_header(conn, "location") == ["/it"]
  end

  test "set/2 does not overwrite session for unsupported locale" do
    conn =
      conn(:post, "/locale/unsupported-locale")
      |> init_test_session(%{locale: "it"})
      |> LocaleController.set(%{"locale" => "unsupported-locale"})

    assert get_session(conn, :locale) == "it"
    assert get_resp_header(conn, "location") == ["/"]
  end

  test "set/2 redirects to localized referer when switching to non-default locale" do
    conn =
      conn(:post, "/locale/it")
      |> put_req_header("referer", "/about")
      |> init_test_session(%{})
      |> LocaleController.set(%{"locale" => "it"})

    assert get_resp_header(conn, "location") == ["/it/about"]
  end

  test "set/2 strips locale prefix when switching to default locale" do
    conn =
      conn(:post, "/locale/en")
      |> put_req_header("referer", "/it/about")
      |> init_test_session(%{})
      |> LocaleController.set(%{"locale" => "en"})

    assert get_resp_header(conn, "location") == ["/about"]
  end

  test "set/2 rejects external referer and falls back to root" do
    conn =
      conn(:post, "/locale/en")
      |> put_req_header("referer", "https://evil.example/somewhere")
      |> init_test_session(%{})
      |> LocaleController.set(%{"locale" => "en"})

    assert get_resp_header(conn, "location") == ["/"]
  end
end
