defmodule DailyLogosWeb.PageControllerIntegrationTest do
  use DailyLogosWeb.ConnCase

  import DailyLogos.QuotesFixtures

  test "localized home persists the language and both logos link to that home", %{conn: conn} do
    conn = conn |> init_test_session(%{locale: "en"}) |> get("/it")
    document = conn |> html_response(200) |> LazyHTML.from_document()
    assert get_session(conn, :locale) == "it"

    for selector <- [
          "header a:has(img[alt='Daily Logos'])",
          "#mobile-menu a:has(img[alt='Daily Logos'])"
        ] do
      assert LazyHTML.attribute(LazyHTML.query(document, selector), "href") == ["/it/"]
    end

    conn = conn |> recycle() |> get("/")
    assert redirected_to(conn) == "/it"
  end

  test "does not cache session-dependent HTML or replay consumed flash messages", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{"phoenix_flash" => %{"info" => "Account deleted"}})
      |> get("/")

    assert get_resp_header(conn, "cache-control") == ["no-store, private"]
    document = conn |> html_response(200) |> LazyHTML.from_document()
    assert Enum.count(LazyHTML.query(document, "#flash-info")) == 1

    conn = conn |> recycle() |> get("/")
    document = conn |> html_response(200) |> LazyHTML.from_document()
    assert Enum.empty?(LazyHTML.query(document, "#flash-info"))
  end

  describe "GET /:month/:day" do
    test "renders quote page for the 1st of January", %{conn: conn} do
      quote_fixture(%{day: 1, month: 1})
      conn = get(conn, "/1/1")
      assert html_response(conn, 200) =~ "Daily Logos"
    end

    test "renders Italian quote page for the 1st of January", %{conn: conn} do
      quote_fixture(%{day: 1, month: 1})
      conn = get(conn, "/it/1/1")
      assert html_response(conn, 200) =~ "Daily Logos"
    end

    test "renders leap day and includes it in calendar navigation", %{conn: conn} do
      quote_fixture(%{day: 29, month: 2})
      conn = get(conn, "/2/29")
      document = conn |> html_response(200) |> LazyHTML.from_document()

      assert document
             |> LazyHTML.query("a[aria-label='Previous day'][href='/2/28']")
             |> Enum.any?()

      assert document
             |> LazyHTML.query("a[aria-label='Next day'][href='/3/1']")
             |> Enum.any?()

      quote_fixture(%{day: 28, month: 2})
      document = get(conn, "/2/28") |> html_response(200) |> LazyHTML.from_document()

      assert document
             |> LazyHTML.query("a[aria-label='Next day'][href='/2/29']")
             |> Enum.any?()
    end

    test "returns 404 when no quote exists for the given day", %{conn: conn} do
      conn = get(conn, "/13/41")
      assert conn.status == 404
    end

    test "returns 404 when no quote exists for a valid calendar date", %{conn: conn} do
      conn = get(conn, "/2/29")
      assert conn.status == 404
    end
  end
end
