defmodule DailyLogosWeb.PageControllerIntegrationTest do
  use DailyLogosWeb.ConnCase

  import DailyLogos.QuotesFixtures

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

    test "returns 404 when no quote exists for the given day", %{conn: conn} do
      conn = get(conn, "/13/41")
      assert conn.status == 404
    end
  end
end
