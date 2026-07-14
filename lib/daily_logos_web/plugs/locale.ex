defmodule DailyLogosWeb.Plugs.Locale do
  @moduledoc """
  Determines the request locale from the URL path prefix, session, or Accept-Language header.

  Priority: path prefix (`/:locale_prefix`) > session > Accept-Language > default.
  Path visits do not update the session — only explicit locale switches do.

  Auto-redirects canonical routes to their localized equivalent when the browser language
  is a supported non-default locale and no session preference is set.
  """

  import Plug.Conn

  @locales Gettext.known_locales(DailyLogosWeb.Gettext)
  @default_locale Application.compile_env(:daily_logos, :i18n)[:default_locale]
  @non_default_locales @locales -- [@default_locale]

  def init(default), do: default

  def call(%{path_params: %{"locale_prefix" => locale}} = conn, _opts)
      when locale in @non_default_locales do
    set_locale(conn, locale)
  end

  def call(%{path_params: %{"locale_prefix" => locale}} = conn, _opts) do
    canonical = strip_locale_from_path(conn.request_path, locale)

    conn
    |> Phoenix.Controller.redirect(to: canonical)
    |> halt()
  end

  def call(conn, _opts) do
    handle_locale(conn, detect_locale_from_session(conn))
  end

  defp handle_locale(conn, session_locale) when is_binary(session_locale) do
    if session_locale in @non_default_locales do
      localized = localized_path(conn.request_path, conn.query_string, session_locale)

      conn
      |> Phoenix.Controller.redirect(to: localized)
      |> halt()
    else
      set_locale(conn, session_locale)
    end
  end

  defp handle_locale(conn, nil) do
    locale = detect_locale_from_header(conn) || @default_locale

    if locale in @non_default_locales do
      localized = localized_path(conn.request_path, conn.query_string, locale)

      conn
      |> Phoenix.Controller.redirect(to: localized)
      |> halt()
    else
      set_locale(conn, locale)
    end
  end

  defp set_locale(conn, locale) do
    Gettext.put_locale(DailyLogosWeb.Gettext, locale)
    assign(conn, :locale, locale)
  end

  defp detect_locale_from_session(conn) do
    case get_session(conn, :locale) do
      locale when locale in @locales -> locale
      _ -> nil
    end
  end

  defp strip_locale_from_path(path, locale) do
    prefix = "/" <> locale

    cond do
      path == prefix -> "/"
      String.starts_with?(path, prefix <> "/") -> String.replace_prefix(path, prefix, "")
      true -> "/"
    end
  end

  defp localized_path(path, query_string, locale) do
    base = "/#{locale}#{path}" |> String.trim_trailing("/")

    case query_string do
      "" -> base
      nil -> base
      query -> "#{base}?#{query}"
    end
  end

  defp detect_locale_from_header(conn) do
    conn
    |> get_req_header("accept-language")
    |> List.first()
    |> parse_locale()
  end

  defp parse_locale(nil), do: nil

  defp parse_locale(header) do
    header
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn part -> part |> String.split(";") |> hd() end)
    |> Enum.map(&String.downcase/1)
    |> Enum.map(fn lang -> String.slice(lang, 0, 2) end)
    |> Enum.find(&(&1 in @locales))
  end
end
