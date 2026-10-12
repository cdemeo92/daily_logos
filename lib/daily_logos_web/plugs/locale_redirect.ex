defmodule DailyLogosWeb.Plugs.LocaleRedirect do
  @moduledoc """
  Redirects GET requests to the canonical URL for the locale assigned by `SetLocale`.

  This plug should run after `SetLocale` and only in pipelines for display routes.
  """

  import Plug.Conn

  @locales Gettext.known_locales(DailyLogosWeb.Gettext)
  @default_locale Application.compile_env(:daily_logos, :i18n)[:default_locale]

  def init(opts), do: opts

  def call(%Plug.Conn{method: "GET"} = conn, _opts) do
    cond do
      conn.assigns[:invalid_locale_prefix] ->
        conn

      path_locale(conn) == @default_locale ->
        redirect(conn, canonical_path(conn.request_path, conn.query_string, @default_locale))

      path_locale(conn) in @locales ->
        conn

      conn.assigns[:locale] in (@locales -- [@default_locale]) ->
        redirect(conn, localized_path(conn.request_path, conn.query_string, conn.assigns.locale))

      true ->
        conn
    end
  end

  def call(conn, _opts), do: conn

  defp redirect(conn, path) do
    conn
    |> Phoenix.Controller.redirect(to: path)
    |> halt()
  end

  defp path_locale(conn) do
    Map.get(conn.path_params || %{}, "locale_prefix") ||
      case conn.path_info do
        [locale | _] when locale in @locales -> locale
        _ -> nil
      end
  end

  defp localized_path(path, query_string, locale) do
    base = "/#{locale}#{path}" |> String.trim_trailing("/")
    append_query(base, query_string)
  end

  defp canonical_path(path, query_string, locale) do
    path = String.replace(path, ~r{/+}, "/")
    prefix = "/" <> locale

    base =
      cond do
        path == prefix -> "/"
        String.starts_with?(path, prefix <> "/") -> String.replace_prefix(path, prefix, "")
        true -> path
      end

    append_query(base, query_string)
  end

  defp append_query(path, query_string) when query_string in [nil, ""], do: path
  defp append_query(path, query_string), do: path <> "?" <> query_string
end
