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

    assert meta.robots == "index,follow"
    assert meta.type == "website"
    assert meta.site_name == "Daily Logos"
    assert meta.twitter_card == "summary_large_image"
    assert meta.canonical == DailyLogosWeb.Endpoint.url() <> "/about?ref=menu"
    assert meta.image == DailyLogosWeb.Endpoint.url() <> "/images/logo.svg"
    assert meta.image_alt == "Daily Logos"
    assert meta.og_locale == "it_IT"

    assert %{"@context" => "https://schema.org", "@graph" => graph} = meta.structured_data
    assert Enum.any?(graph, &(&1["@type"] == "WebSite"))
    assert Enum.any?(graph, &(&1["@type"] == "Organization"))

    assert Enum.any?(graph, fn item ->
             item["@type"] == "WebPage" and item["url"] == meta.canonical
           end)
  end

  test "merges page overrides and normalizes relative urls", %{conn: conn} do
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

    assert meta.title == "Support Daily Logos"
    assert meta.description == "Support page"
    assert meta.robots == "noindex,nofollow"
    assert meta.canonical == DailyLogosWeb.Endpoint.url() <> "/support"
    assert meta.image == DailyLogosWeb.Endpoint.url() <> "/images/logo_white.svg"
    assert meta.og_locale == "en_US"

    assert Enum.any?(meta.structured_data["@graph"], fn item ->
             item["@type"] == "WebPage" and item["name"] == "Support Daily Logos" and
               item["description"] == "Support page"
           end)
  end
end
