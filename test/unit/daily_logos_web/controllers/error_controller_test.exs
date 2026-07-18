defmodule DailyLogosWeb.ErrorControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  @endpoint DailyLogosWeb.Endpoint

  setup_all do
    Application.ensure_all_started(:plug)

    case Process.whereis(DailyLogosWeb.Endpoint) do
      nil -> start_supervised!(DailyLogosWeb.Endpoint)
      _pid -> :ok
    end

    :ok
  end

  setup do
    {:ok, conn: build_conn()}
  end

  test "GET /api/not-exist should return not found", %{conn: conn} do
    conn = get(conn, "/api/not-exist")
    assert json_response(conn, 404) == %{"errors" => %{"detail" => "Not Found"}}
  end
end
