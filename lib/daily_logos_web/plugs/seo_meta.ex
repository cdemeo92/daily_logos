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
        canonical: endpoint_url <> canonical_path(conn),
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
    |> assign(:page_title, page_meta[:title] || conn.assigns.page_title)
    |> assign(:page_description, page_meta[:description] || conn.assigns.page_description)
    |> assign(:page_robots, page_meta[:robots] || "index,follow")
    |> assign(:page_image, page_meta[:image] || seo_meta.image)
    |> assign(:keywords, page_meta[:keywords] || seo_meta.keywords)
  end

  defp build_alternates(conn, endpoint_url) do
    base = localized_base_path(conn)

    locale_links =
      Enum.map(@locales, fn locale ->
        %{hreflang: locale, href: endpoint_url <> alternate_path(locale, base)}
      end)

    [%{hreflang: "x-default", href: endpoint_url <> base} | locale_links]
  end

  defp canonical_path(conn) do
    path = String.replace(conn.request_path, ~r{/+}, "/")
    if path == "/", do: path, else: String.trim_trailing(path, "/")
  end

  defp localized_base_path(conn) do
    Enum.reduce_while(@non_default_locales, canonical_path(conn), fn locale, path ->
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

  defp alternate_path(locale, base) when locale == @default_locale, do: base
  defp alternate_path(locale, "/"), do: "/" <> locale
  defp alternate_path(locale, base), do: "/" <> locale <> base

  defp og_locale("it"), do: "it_IT"
  defp og_locale(_), do: "en_US"
end
