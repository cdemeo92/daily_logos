defmodule DailyLogosWeb.Plugs.SeoMeta do
  @moduledoc """
  Assigns default SEO metadata and hreflang alternates for multi-language support.
  Page-specific metadata is passed via render() from controllers.
  """

  use Gettext, backend: DailyLogosWeb.Gettext

  import Plug.Conn

  @locales Gettext.known_locales(DailyLogosWeb.Gettext)
  @default_locale Application.compile_env(:daily_logos, :i18n)[:default_locale]
  @non_default_locales @locales -- [@default_locale]

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = conn.assigns[:locale] || Gettext.get_locale(DailyLogosWeb.Gettext)
    endpoint_url = DailyLogosWeb.Endpoint.url()

    Gettext.with_locale(DailyLogosWeb.Gettext, locale, fn ->
      seo_meta = %{
        title: gettext("Daily Logos"),
        description:
          gettext("A daily Stoic quote to reflect, act better, and live with intention."),
        site_name: gettext("Daily Logos"),
        image: endpoint_url <> "/images/logo.svg",
        image_alt: gettext("Daily Logos"),
        og_locale: og_locale(locale),
        endpoint_url: endpoint_url,
        canonical: current_url(conn),
        alternates: build_alternates(conn, endpoint_url),
        keywords:
          gettext(
            "stoic, philosophy, quotes, daily, reflection, wisdom, marcus aurelio, epictetus, seneca, stoicism"
          )
      }

      conn
      |> assign(:seo_meta, seo_meta)
      |> assign(:page_title, seo_meta.title)
      |> assign(:page_description, seo_meta.description)
      |> assign(:page_image, seo_meta.image)
      |> assign(:keywords, seo_meta.keywords)
      |> assign(:page_robots, "index,follow")
    end)
  end

  def put_page_meta(conn, page_meta) do
    seo_meta = conn.assigns[:seo_meta]

    conn
    |> assign(:page_title, page_meta.title)
    |> assign(:page_description, page_meta.description)
    |> assign(:page_robots, page_meta[:robots] || "index,follow")
    |> assign(:page_image, page_meta[:image] || seo_meta.image)
    |> assign(:keywords, page_meta[:keywords] || seo_meta.keywords)
  end

  defp build_alternates(conn, endpoint_url) do
    base = canonical_path(conn)

    locale_links =
      Enum.map(@locales, fn locale ->
        href =
          if locale in @non_default_locales,
            do: endpoint_url <> "/" <> locale <> base,
            else: endpoint_url <> base

        %{hreflang: locale, href: href}
      end)

    [%{hreflang: "x-default", href: endpoint_url <> base} | locale_links]
  end

  defp canonical_path(conn) do
    Enum.reduce_while(@non_default_locales, conn.request_path, fn locale, path ->
      prefix = "/" <> locale

      cond do
        path == prefix ->
          {:halt, "/"}

        String.starts_with?(path, prefix <> "/") ->
          {:halt, String.replace_prefix(path, prefix, "")}

        true ->
          {:cont, path}
      end
    end)
  end

  defp current_url(conn) do
    DailyLogosWeb.Endpoint.url() <> request_path_with_query(conn)
  end

  defp request_path_with_query(%Plug.Conn{query_string: "", request_path: request_path}),
    do: request_path

  defp request_path_with_query(%Plug.Conn{query_string: query_string, request_path: request_path}),
    do: request_path <> "?" <> query_string

  defp og_locale("it"), do: "it_IT"
  defp og_locale(_), do: "en_US"
end
