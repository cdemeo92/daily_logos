defmodule DailyLogosWeb.Plugs.InvalidLocalePrefixTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias DailyLogosWeb.Layouts
  alias DailyLogosWeb.Plugs.InvalidLocalePrefix
  alias DailyLogosWeb.Plugs.SeoMeta

  setup_all do
    start_supervised!(DailyLogosWeb.Endpoint)
    :ok
  end

  setup do
    conn =
      build_conn()
      |> fetch_query_params()
      |> Map.put(:params, %{"_format" => "html"})
      |> assign(:locale, "en")
      |> assign(:current_scope, nil)
      |> assign(:flash, %{})
      |> SeoMeta.call([])
      |> Phoenix.Controller.put_root_layout(html: {Layouts, :root})

    {:ok, conn: conn}
  end

  test "renders the shared 404 and halts for an unsupported locale prefix", %{conn: conn} do
    conn =
      conn
      |> assign(:invalid_locale_prefix, true)
      |> InvalidLocalePrefix.call([])

    assert conn.halted
    assert html_response(conn, 404) =~ "Page Not Found"
  end

  test "passes through requests without an invalid locale prefix", %{conn: conn} do
    assert InvalidLocalePrefix.call(conn, []) == conn
  end
end
