defmodule DailyLogosWeb.QuoteControllerTest do
  use DailyLogosWeb.ConnCase

  import DailyLogos.QuotesFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show quote" do
    test "show a quote by day and month", %{conn: conn} do
      quote = quote_fixture()
      conn = get(conn, ~p"/api/v1/quotes?day=#{quote.day}&month=#{quote.month}")
      assert json_response(conn, 200)["data"]["day"] == quote.day
      assert json_response(conn, 200)["data"]["month"] == quote.month
      assert json_response(conn, 200)["data"]["text_en"] == quote.text_en
      assert json_response(conn, 200)["data"]["text_it"] == quote.text_it
    end
  end
end
