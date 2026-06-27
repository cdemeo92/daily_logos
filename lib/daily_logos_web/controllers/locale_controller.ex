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
    case List.first(get_req_header(conn, "referer")) do
      <<"/", _::binary>> = path ->
        if String.starts_with?(path, "//"), do: "/", else: path

      _ ->
        "/"
    end
  end
end
