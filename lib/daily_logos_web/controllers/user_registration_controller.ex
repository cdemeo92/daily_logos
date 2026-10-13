defmodule DailyLogosWeb.UserRegistrationController do
  use DailyLogosWeb, :controller

  alias DailyLogos.Accounts
  alias DailyLogos.Accounts.User
  alias DailyLogosWeb.Plugs.InvalidLocalePrefix
  alias DailyLogosWeb.UserAuth

  plug InvalidLocalePrefix when action == :new
  plug DailyLogosWeb.Plugs.AuthRateLimit when action == :create

  def new(conn, params) do
    conn = UserAuth.store_notifications_return_to(conn, params)
    changeset = Accounts.change_user_email(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        conn
        |> put_flash(
          :info,
          gettext("An email was sent to %{email}, please access it to confirm your account.",
            email: user.email
          )
        )
        |> redirect(to: ~p"/users/log-in")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
