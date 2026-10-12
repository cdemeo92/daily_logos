defmodule DailyLogosWeb.Plugs.InvalidLocalePrefix do
  @moduledoc """
  Renders the shared 404 page when a localized route has an unsupported prefix.
  """

  @behaviour Plug

  use Gettext, backend: DailyLogosWeb.Gettext

  import Phoenix.Controller
  import Plug.Conn

  alias DailyLogosWeb.PageHTML
  alias DailyLogosWeb.Plugs.SeoMeta

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{assigns: %{invalid_locale_prefix: true}} = conn, _opts) do
    conn
    |> put_view(html: PageHTML)
    |> put_status(:not_found)
    |> SeoMeta.put_page_meta(%{
      title: gettext("Page Not Found") <> " | Daily Logos",
      description: gettext("The page you requested does not exist."),
      robots: "noindex,nofollow,noarchive"
    })
    |> render(:not_found)
    |> halt()
  end

  def call(conn, _opts), do: conn
end
