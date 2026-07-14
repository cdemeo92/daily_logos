defmodule DailyLogosWeb.LocaleController do
  use DailyLogosWeb, :controller

  @locales Gettext.known_locales(DailyLogosWeb.Gettext)
  @default_locale Application.compile_env(:daily_logos, :i18n)[:default_locale]
  @non_default_locales @locales -- [@default_locale]

  def set(conn, %{"locale" => locale}) when locale in @locales do
    conn
    |> put_session(:locale, locale)
    |> redirect(to: localized_path(safe_path(conn), locale))
  end

  def set(conn, _params) do
    redirect(conn, to: safe_path(conn))
  end

  defp localized_path(path, locale) when locale in @non_default_locales do
    "/#{locale}#{path}" |> String.trim_trailing("/")
  end

  defp localized_path(path, _locale), do: path

  defp safe_path(conn) do
    conn
    |> get_req_header("referer")
    |> List.first()
    |> extract_canonical_path(conn.host)
  end

  defp extract_canonical_path(nil, _host), do: "/"

  defp extract_canonical_path(referer, request_host) do
    case URI.parse(referer) do
      %URI{host: host, path: path, query: query} when is_binary(path) ->
        if host == nil or host == request_host do
          path |> strip_known_locale_prefix() |> build_path(query)
        else
          "/"
        end

      _ ->
        "/"
    end
  end

  defp strip_known_locale_prefix(path) do
    Enum.reduce_while(@non_default_locales, path, fn locale, acc ->
      prefix = "/" <> locale

      cond do
        acc == prefix -> {:halt, "/"}
        String.starts_with?(acc, prefix <> "/") -> {:halt, String.replace_prefix(acc, prefix, "")}
        true -> {:cont, acc}
      end
    end)
  end

  defp build_path(path, nil), do: path
  defp build_path(path, query), do: "#{path}?#{query}"
end
