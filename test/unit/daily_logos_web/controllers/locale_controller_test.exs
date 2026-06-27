defmodule DailyLogosWeb.LocaleControllerUnitTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias DailyLogosWeb.LocaleController

  for locale <- ["en", "it"] do
    test "set/2 stores supported locale #{locale} in session" do
      conn =
        conn(:post, "/locale/#{unquote(locale)}")
        |> init_test_session(%{})
        |> LocaleController.set(%{"locale" => unquote(locale)})

      assert get_session(conn, :locale) == unquote(locale)
      assert get_resp_header(conn, "location") == ["/"]
    end
  end

  test "set/2 does not overwrite session for unsupported locale" do
    conn =
      conn(:post, "/locale/unsupported-locale")
      |> init_test_session(%{locale: "it"})
      |> LocaleController.set(%{"locale" => "unsupported-locale"})

    assert get_session(conn, :locale) == "it"
    assert get_resp_header(conn, "location") == ["/"]
  end

  test "set/2 redirects to internal referer" do
    conn =
      conn(:post, "/locale/en")
      |> put_req_header("referer", "/some-page")
      |> init_test_session(%{})
      |> LocaleController.set(%{"locale" => "en"})

    assert get_resp_header(conn, "location") == ["/some-page"]
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
