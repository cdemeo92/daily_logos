defmodule DailyLogosWeb.Plugs.SeoMetaTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias DailyLogosWeb.Plugs.SeoMeta

  setup_all do
    start_supervised!(DailyLogosWeb.Endpoint)
    :ok
  end

  test "assigns default seo metadata" do
    conn =
      build_conn()
      |> Map.put(:request_path, "/it/about")
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
    assert meta.canonical == DailyLogosWeb.Endpoint.url() <> "/it/about"
    assert meta.image == DailyLogosWeb.Endpoint.url() <> "/images/logo.svg"
    assert meta.image_alt == "Daily Logos"
    assert meta.og_locale == "it_IT"
    assert conn.assigns.page_title == meta.title
    assert conn.assigns.page_description == meta.description
    assert conn.assigns.page_image == meta.image
    assert conn.assigns.keywords == meta.keywords
    assert conn.assigns.page_robots == "index,follow"

    assert %{href: endpoint_url} = Enum.find(meta.alternates, &(&1.hreflang == "x-default"))
    assert endpoint_url == DailyLogosWeb.Endpoint.url() <> "/about"
    assert %{href: endpoint_url} = Enum.find(meta.alternates, &(&1.hreflang == "en"))
    assert endpoint_url == DailyLogosWeb.Endpoint.url() <> "/about"
    assert %{href: endpoint_url} = Enum.find(meta.alternates, &(&1.hreflang == "it"))
    assert endpoint_url == DailyLogosWeb.Endpoint.url() <> "/it/about"
  end

  test "keeps a localized home canonical when its path has a trailing slash" do
    conn =
      build_conn()
      |> Map.put(:request_path, "/it/")
      |> Plug.Conn.assign(:locale, "it")
      |> SeoMeta.call(SeoMeta.init([]))

    meta = conn.assigns.seo_meta

    assert meta.canonical == DailyLogosWeb.Endpoint.url() <> "/it"
    assert %{href: endpoint_url} = Enum.find(meta.alternates, &(&1.hreflang == "en"))
    assert endpoint_url == DailyLogosWeb.Endpoint.url() <> "/"
    assert %{href: endpoint_url} = Enum.find(meta.alternates, &(&1.hreflang == "it"))
    assert endpoint_url == DailyLogosWeb.Endpoint.url() <> "/it"
  end

  test "applies page overrides to page assigns" do
    conn =
      build_conn()
      |> Map.put(:request_path, "/about")
      |> Plug.Conn.assign(:locale, "en")
      |> SeoMeta.call(SeoMeta.init([]))

    conn =
      SeoMeta.put_page_meta(conn, %{
        title: "Custom Page Title",
        description: "Custom page description",
        robots: "noindex,nofollow",
        canonical: "/about",
        image: "/images/logo_white.svg",
        keywords: "custom, page"
      })

    meta = conn.assigns.seo_meta

    assert meta.title == "Daily Logos"

    assert meta.description ==
             "A daily Stoic quote to reflect, act better, and live with intention."

    assert meta.canonical == DailyLogosWeb.Endpoint.url() <> "/about"
    assert meta.image == DailyLogosWeb.Endpoint.url() <> "/images/logo.svg"
    assert meta.og_locale == "en_US"

    assert conn.assigns.page_title == "Custom Page Title"
    assert conn.assigns.page_description == "Custom page description"
    assert conn.assigns.page_robots == "noindex,nofollow"
    assert conn.assigns.page_image == "/images/logo_white.svg"
    assert conn.assigns.keywords == "custom, page"
  end

  test "uses default keywords when page override does not provide them" do
    conn =
      build_conn()
      |> Map.put(:request_path, "/about")
      |> Plug.Conn.assign(:locale, "en")
      |> SeoMeta.call(SeoMeta.init([]))

    default_keywords = conn.assigns.seo_meta.keywords

    conn =
      SeoMeta.put_page_meta(conn, %{
        title: "About Daily Logos",
        description: "About page"
      })

    assert conn.assigns.keywords == default_keywords
  end

  test "allows overriding robots while preserving default title and description" do
    conn =
      build_conn()
      |> Map.put(:request_path, "/users/log-in")
      |> Plug.Conn.assign(:locale, "en")
      |> SeoMeta.call(SeoMeta.init([]))

    conn = SeoMeta.put_page_meta(conn, %{robots: "noindex,follow"})

    assert conn.assigns.page_robots == "noindex,follow"
    assert conn.assigns.page_title == conn.assigns.seo_meta.title
    assert conn.assigns.page_description == conn.assigns.seo_meta.description
  end
end
