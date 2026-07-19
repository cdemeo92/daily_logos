defmodule DailyLogosWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use DailyLogosWeb, :html

  @locales Gettext.known_locales(DailyLogosWeb.Gettext)
  @default_locale Application.compile_env(:daily_logos, :i18n)[:default_locale]

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/daily_logos_web/controllers/error_html/404.html.heex
  #   * lib/daily_logos_web/controllers/error_html/500.html.heex
  #
  embed_templates "error_html/*"

  def render("404", assigns) do
    locale = detect_error_locale(assigns)
    Gettext.put_locale(DailyLogosWeb.Gettext, locale)

    assigns
    |> Map.put(:locale, locale)
    |> then(&apply(__MODULE__, :"404", [&1]))
  end

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  defp detect_error_locale(assigns) do
    case assigns do
      %{reason: %{conn: conn}} -> detect_locale_from_conn(conn) || @default_locale
      _ -> @default_locale
    end
  end

  defp detect_locale_from_conn(conn) do
    detect_locale_from_path(conn.request_path) || detect_locale_from_header(conn)
  end

  defp detect_locale_from_path(path) when is_binary(path) do
    case String.split(path, "/", trim: true) do
      [locale | _] when locale in @locales -> locale
      _ -> nil
    end
  end

  defp detect_locale_from_path(_), do: nil

  defp detect_locale_from_header(conn) do
    conn
    |> Plug.Conn.get_req_header("accept-language")
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
