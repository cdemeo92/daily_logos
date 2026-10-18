defmodule DailyLogosWeb.EmailVerification do
  @moduledoc "Delivers local sign-in links and redirects to a persistent confirmation page."

  use DailyLogosWeb, :verified_routes
  use Gettext, backend: DailyLogosWeb.Gettext

  import Phoenix.Controller
  import Plug.Conn

  alias DailyLogos.Accounts
  alias DailyLogosWeb.LocalePaths

  def deliver_and_redirect(conn, user) do
    locale = conn.assigns[:locale] || Gettext.get_locale(DailyLogosWeb.Gettext)

    case Accounts.deliver_login_instructions(user, fn token ->
           DailyLogosWeb.Endpoint.url() <>
             LocalePaths.localized_path(~p"/users/log-in/#{token}", locale)
         end) do
      {:ok, _email} ->
        conn
        |> put_session(:locale, locale)
        |> redirect(to: LocalePaths.localized_path(~p"/users/verify-email", locale))

      {:error, _reason} ->
        conn
        |> put_flash(
          :error,
          gettext("We could not send the email. Please request another sign-in link.")
        )
        |> redirect(to: LocalePaths.localized_path(~p"/users/log-in", locale))
    end
  end
end
