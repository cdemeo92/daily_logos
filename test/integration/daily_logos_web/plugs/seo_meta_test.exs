defmodule DailyLogosWeb.Plugs.SeoMetaTest do
  use DailyLogosWeb.ConnCase

  alias DailyLogosWeb.Plugs.SeoMeta

  test "assigns default seo metadata", %{conn: conn} do
    conn =
      conn
      |> Map.put(:request_path, "/about")
      |> Map.put(:query_string, "ref=menu")
      |> Plug.Conn.assign(:locale, "it")

    conn = SeoMeta.call(conn, SeoMeta.init([]))
    meta = conn.assigns.seo_meta

    assert meta.title ==
             Gettext.with_locale(DailyLogosWeb.Gettext, "it", fn ->
               Gettext.dgettext(DailyLogosWeb.Gettext, "default", "Daily Logos")
             end)

    assert meta.description ==
             Gettext.with_locale(DailyLogosWeb.Gettext, "it", fn ->
               Gettext.dgettext(
                 DailyLogosWeb.Gettext,
                 "default",
                 "A daily Stoic quote to reflect, act better, and live with intention."
               )
             end)

    assert meta.site_name == "Daily Logos"
    assert meta.canonical == DailyLogosWeb.Endpoint.url() <> "/about?ref=menu"
    assert meta.image == DailyLogosWeb.Endpoint.url() <> "/images/logo.svg"
    assert meta.image_alt == "Daily Logos"
    assert meta.og_locale == "it_IT"
    assert conn.assigns.page_title == meta.title
    assert conn.assigns.page_description == meta.description
    assert conn.assigns.page_image == meta.image
    assert conn.assigns.page_robots == "index,follow"

    assert Enum.any?(meta.alternates, &(&1.hreflang == "x-default"))
    assert Enum.any?(meta.alternates, &(&1.hreflang == "en"))
    assert Enum.any?(meta.alternates, &(&1.hreflang == "it"))
  end

  test "applies page overrides to page assigns", %{conn: conn} do
    conn =
      conn
      |> Map.put(:request_path, "/support")
      |> Plug.Conn.assign(:locale, "en")
      |> SeoMeta.call(SeoMeta.init([]))

    conn =
      SeoMeta.put_page_meta(conn, %{
        title: "Support Daily Logos",
        description: "Support page",
        robots: "noindex,nofollow",
        canonical: "/support",
        image: "/images/logo_white.svg"
      })

    meta = conn.assigns.seo_meta

    assert meta.title == "Daily Logos"

    assert meta.description ==
             "A daily Stoic quote to reflect, act better, and live with intention."

    assert meta.canonical == DailyLogosWeb.Endpoint.url() <> "/support"
    assert meta.image == DailyLogosWeb.Endpoint.url() <> "/images/logo.svg"
    assert meta.og_locale == "en_US"

    assert conn.assigns.page_title == "Support Daily Logos"
    assert conn.assigns.page_description == "Support page"
    assert conn.assigns.page_robots == "noindex,nofollow"
    assert conn.assigns.page_image == "/images/logo_white.svg"
  end
end
