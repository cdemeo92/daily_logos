defmodule DailyLogosWeb.UserSessionController do
  use DailyLogosWeb, :controller

  alias DailyLogos.Accounts
  alias DailyLogos.AuthProviders
  alias DailyLogosWeb.Plugs.InvalidLocalePrefix
  alias DailyLogosWeb.Plugs.SeoMeta
  alias DailyLogosWeb.UserAuth

  plug InvalidLocalePrefix when action in [:new, :confirm]
  plug DailyLogosWeb.Plugs.AuthRateLimit when action == :create

  def new(conn, params) do
    conn = UserAuth.store_notifications_return_to(conn, params)
    email = get_in(conn.assigns, [:current_scope, Access.key(:user), Access.key(:email)])
    form = Phoenix.Component.to_form(%{"email" => email}, as: "user")

    render_login(conn, form)
  end

  defp render_login(conn, form) do
    current_user = get_in(conn.assigns, [:current_scope, Access.key(:user)])
    oauth_providers = if current_user, do: [], else: AuthProviders.available_providers()
    stored_last_provider = get_session(conn, :last_oauth_provider)

    last_oauth_provider =
      if Enum.any?(oauth_providers, &(&1.id == stored_last_provider)), do: stored_last_provider

    render(conn, :new,
      form: form,
      oauth_providers: oauth_providers,
      last_oauth_provider: last_oauth_provider
    )
  end

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> gettext("User confirmed successfully.")
        _ -> gettext("Welcome back!")
      end

    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, _expired_tokens}} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, gettext("The link is invalid or it has expired."))
        |> render_login(Phoenix.Component.to_form(%{}, as: "user"))
    end
  end

  # email + password login
  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, gettext("Welcome back!"))
      |> UserAuth.log_in_user(user, user_params)
    else
      form = Phoenix.Component.to_form(user_params, as: "user")

      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, gettext("Invalid email or password"))
      |> render_login(form)
    end
  end

  # magic link request
  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      gettext(
        "If your email is in our system, you will receive instructions for logging in shortly."
      )

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/users/log-in")
  end

  def confirm(conn, %{"token" => token}) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = Phoenix.Component.to_form(%{"token" => token}, as: "user")

      conn
      |> SeoMeta.put_page_meta(%{robots: "noindex,nofollow,noarchive"})
      |> assign(:user, user)
      |> assign(:form, form)
      |> render(:confirm)
    else
      conn
      |> put_flash(:error, gettext("Magic link is invalid or it has expired."))
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out successfully."))
    |> UserAuth.log_out_user()
  end
end
