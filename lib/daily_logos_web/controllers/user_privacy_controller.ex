defmodule DailyLogosWeb.UserPrivacyController do
  use DailyLogosWeb, :controller

  alias DailyLogos.Accounts
  alias DailyLogosWeb.Plugs.SeoMeta
  alias DailyLogosWeb.UserAuth

  import DailyLogosWeb.UserAuth, only: [require_sudo_mode: 2]

  plug :store_return_to_privacy when action == :delete
  plug :require_sudo_mode when action == :delete

  def edit(conn, _params) do
    conn
    |> SeoMeta.put_page_meta(%{
      title: gettext("Privacy settings | Daily Logos"),
      description: gettext("Manage your account privacy settings."),
      robots: "noindex,nofollow,noarchive"
    })
    |> assign(:form, Phoenix.Component.to_form(%{}, as: :privacy))
    |> render(:edit)
  end

  def delete(conn, %{"privacy" => %{"confirm" => "true"}}) do
    case Accounts.delete_user(conn.assigns.current_scope.user) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, gettext("Your account has been permanently deleted."))
        |> UserAuth.log_out_user()

      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("Your account could not be deleted. Please try again."))
        |> redirect(to: ~p"/users/account/privacy")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:error, gettext("Confirm account deletion before continuing."))
    |> redirect(to: ~p"/users/account/privacy")
  end

  defp store_return_to_privacy(conn, _opts) do
    Plug.Conn.put_session(conn, :user_return_to, ~p"/users/account/privacy")
  end
end
