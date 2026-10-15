defmodule DailyLogosWeb.HealthControllerTest do
  use DailyLogosWeb.ConnCase

  test "returns healthy when the database is available", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> get(~p"/api/v1/healthz")

    assert json_response(conn, 200) == %{"status" => "ok"}
  end
end
