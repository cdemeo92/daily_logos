defmodule DailyLogosWeb.Plugs.SeoMeta do
  @moduledoc """
  Assigns SEO metadata defaults and provides helpers for per-page overrides.
  """

  use Gettext, backend: DailyLogosWeb.Gettext

  import Plug.Conn

  @default_robots "index,follow"
  @default_type "website"
  @default_twitter_card "summary_large_image"

  def init(opts), do: opts

  def call(conn, _opts) do
    assign(conn, :seo_meta, default_meta(conn))
  end

  def put_page_meta(conn, overrides) when is_map(overrides) do
    base = conn.assigns[:seo_meta] || default_meta(conn)
    assign(conn, :seo_meta, normalize_meta(conn, Map.merge(base, overrides)))
  end

  defp default_meta(conn) do
    endpoint_url = DailyLogosWeb.Endpoint.url()
    locale = conn.assigns[:locale] || Gettext.get_locale(DailyLogosWeb.Gettext)
    canonical = current_url(conn)
    image = endpoint_url <> "/images/logo.svg"

    Gettext.with_locale(DailyLogosWeb.Gettext, locale, fn ->
      title = gettext("Daily Logos")

      description =
        gettext("A daily Stoic quote to reflect, act better, and live with intention.")

      %{
        title: title,
        description: description,
        robots: @default_robots,
        type: @default_type,
        site_name: gettext("Daily Logos"),
        twitter_card: @default_twitter_card,
        canonical: canonical,
        image: image,
        image_alt: gettext("Daily Logos"),
        og_locale: og_locale(locale),
        structured_data: build_structured_data(title, description, canonical, image)
      }
    end)
  end

  defp normalize_meta(conn, meta) do
    endpoint_url = DailyLogosWeb.Endpoint.url()

    canonical =
      case meta[:canonical] do
        nil -> current_url(conn)
        url when is_binary(url) -> normalize_url(url, endpoint_url)
        _ -> current_url(conn)
      end

    image =
      case meta[:image] do
        nil -> endpoint_url <> "/images/logo.svg"
        url when is_binary(url) -> normalize_url(url, endpoint_url)
        _ -> endpoint_url <> "/images/logo.svg"
      end

    locale = conn.assigns[:locale] || Gettext.get_locale(DailyLogosWeb.Gettext)

    meta
    |> Map.put(:canonical, canonical)
    |> Map.put(:image, image)
    |> Map.put_new(:image_alt, "Daily Logos")
    |> Map.put_new(:og_locale, og_locale(locale))
    |> Map.put(
      :structured_data,
      build_structured_data(meta[:title], meta[:description], canonical, image)
    )
  end

  defp normalize_url(url, endpoint_url) do
    if String.starts_with?(url, "http") do
      url
    else
      endpoint_url <> url
    end
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

  defp build_structured_data(title, description, canonical, image) do
    site_url = DailyLogosWeb.Endpoint.url()

    %{
      "@context" => "https://schema.org",
      "@graph" => [
        %{
          "@type" => "WebSite",
          "name" => "Daily Logos",
          "url" => site_url
        },
        %{
          "@type" => "Organization",
          "name" => "Daily Logos",
          "url" => site_url,
          "logo" => %{
            "@type" => "ImageObject",
            "url" => image
          }
        },
        %{
          "@type" => "WebPage",
          "name" => title,
          "url" => canonical,
          "description" => description
        }
      ]
    }
  end
end
