defmodule DailyLogosWeb.Plugs.Locale do
  @moduledoc """
  A plug to set the locale for the request based on the `Accept-Language` header.
  """

  import Plug.Conn

  # Add your supported locales here
  @locales ["en", "it"]
  @default_locale "en"

  def init(default), do: default

  def call(conn, _opts) do
    locale =
      detect_locale_from_session(conn) ||
        detect_locale(conn) ||
        @default_locale

    Gettext.put_locale(DailyLogosWeb.Gettext, locale)

    conn
    |> put_session(:locale, locale)
    |> assign(:locale, locale)
  end

  defp detect_locale_from_session(conn) do
    case get_session(conn, :locale) do
      locale when locale in @locales -> locale
      _ -> nil
    end
  end

  defp detect_locale(conn) do
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
