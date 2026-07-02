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

    test "returns bad_request when the request parameters are invalid", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/quotes?day=invalid&month=invalid")
      errors = json_response(conn, 422)["errors"]
      assert is_list(errors)

      pointers = Enum.map(errors, &get_in(&1, ["source", "pointer"]))
      assert "/day" in pointers
      assert "/month" in pointers
    end

    test "returns bad_request when when day and month are out of range", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/quotes?day=32&month=13")
      errors = json_response(conn, 422)["errors"]
      assert is_list(errors)

      pointers = Enum.map(errors, &get_in(&1, ["source", "pointer"]))
      assert "/day" in pointers
      assert "/month" in pointers
    end

    test "returns not found when the quote does not exist", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/quotes?day=1&month=1")
      assert json_response(conn, 404)["errors"]["detail"] == "Quote not found"
    end
  end
end
