defmodule DailyLogosWeb.UserRegistrationController do
  use DailyLogosWeb, :controller

  alias DailyLogos.Accounts
  alias DailyLogos.Accounts.User
  alias DailyLogos.AuthProviders
  alias DailyLogosWeb.EmailVerification
  alias DailyLogosWeb.Plugs.InvalidLocalePrefix
  alias DailyLogosWeb.Plugs.SeoMeta
  alias DailyLogosWeb.UserAuth

  plug InvalidLocalePrefix when action in [:new, :verify_email]
  plug DailyLogosWeb.Plugs.AuthRateLimit when action == :create

  def new(conn, params) do
    conn = UserAuth.store_notifications_return_to(conn, params)
    changeset = Accounts.change_user_email(%User{})
    render_registration(conn, changeset)
  end

  def verify_email(conn, _params) do
    conn
    |> SeoMeta.put_page_meta(%{robots: "noindex,nofollow,noarchive"})
    |> render(:verify_email)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        EmailVerification.deliver_and_redirect(conn, user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render_registration(conn, changeset)
    end
  end

  defp render_registration(conn, changeset) do
    conn
    |> put_session(:locale, conn.assigns.locale)
    |> render(:new,
      form: Phoenix.Component.to_form(changeset),
      oauth_providers: AuthProviders.available_providers(),
      last_oauth_provider: get_session(conn, :last_oauth_provider)
    )
  end
end
