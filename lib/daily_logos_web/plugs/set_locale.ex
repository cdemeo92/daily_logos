defmodule DailyLogosWeb.Plugs.SetLocale do
  @moduledoc """
  Sets the request locale from the URL path prefix, session, Accept-Language header, or default.

  Priority: path prefix (`/:locale_prefix`) > session > Accept-Language > default.
  This plug never redirects.
  """

  import Plug.Conn

  @locales Gettext.known_locales(DailyLogosWeb.Gettext)
  @default_locale Application.compile_env(:daily_logos, :i18n)[:default_locale]

  def init(opts), do: opts

  def call(conn, _opts) do
    case locale_from_path(conn) do
      locale when locale in @locales ->
        set_locale(conn, locale)

      nil ->
        set_locale(
          conn,
          detect_locale_from_session(conn) || detect_locale_from_header(conn) || @default_locale
        )

      _unsupported_locale ->
        conn
        |> set_locale(
          detect_locale_from_session(conn) || detect_locale_from_header(conn) || @default_locale
        )
        |> assign(:invalid_locale_prefix, true)
    end
  end

  defp set_locale(conn, locale) do
    Gettext.put_locale(DailyLogosWeb.Gettext, locale)
    assign(conn, :locale, locale)
  end

  defp locale_from_path(%{path_params: %{"locale_prefix" => locale}}), do: locale

  defp locale_from_path(%{path_info: [locale | _]}) when locale in @locales, do: locale

  defp locale_from_path(_conn), do: nil

  defp detect_locale_from_session(conn) do
    case get_session(conn, :locale) do
      locale when locale in @locales -> locale
      _ -> nil
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
