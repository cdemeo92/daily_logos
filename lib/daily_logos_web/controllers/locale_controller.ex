defmodule DailyLogosWeb.LocaleController do
  use DailyLogosWeb, :controller

  @locales Gettext.known_locales(DailyLogosWeb.Gettext)

  def set(conn, %{"locale" => locale}) when locale in @locales do
    conn
    |> put_session(:locale, locale)
    |> redirect(to: safe_referer(conn))
  end

  def set(conn, _params) do
    redirect(conn, to: safe_referer(conn))
  end

  defp safe_referer(conn) do
    conn
    |> get_req_header("referer")
    |> List.first()
    |> extract_local_path(conn.host)
  end

  defp extract_local_path(nil, _host), do: "/"

  defp extract_local_path(referer, request_host) do
    case URI.parse(referer) do
      %URI{host: host, path: path, query: query} when is_binary(path) ->
        if same_host?(host, request_host), do: build_path(path, query), else: "/"

      _ ->
        "/"
    end
  end

  defp same_host?(nil, _request_host), do: true
  defp same_host?(host, request_host), do: host == request_host

  defp build_path(path, nil), do: path
  defp build_path(path, query), do: "#{path}?#{query}"
end
