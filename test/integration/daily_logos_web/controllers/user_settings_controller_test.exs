defmodule DailyLogosWeb.UserSettingsControllerTest do
  use DailyLogosWeb.ConnCase, async: true

  alias DailyLogos.Accounts
  import DailyLogos.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /notifications" do
    test "shows the coming soon state to authenticated users", %{conn: conn} do
      response = conn |> get("/notifications") |> html_response(200)

      assert response =~ "Notifications"
      assert response =~ "Coming soon"
      assert response =~ "Notification settings are not available yet."
    end

    test "shows the notification signup landing to anonymous users" do
      response = build_conn() |> get("/notifications") |> html_response(200)

      assert response =~ "Want to receive the daily quote and feel inspired?"

      assert response =~
               "Create an account and be ready to choose when and how to receive your daily quote."

      assert response =~ ~s(href="/users/register?return_to=%2Fnotifications")
      assert response =~ ~s(href="/users/log-in?return_to=%2Fnotifications")
      refute response =~ "Notification settings are coming soon."
      refute response =~ "notifications-coming-soon"

      mobile_menu =
        LazyHTML.query(
          LazyHTML.from_document(response),
          "#mobile-menu nav[aria-label='Primary navigation'] a"
        )

      assert LazyHTML.attribute(mobile_menu, "href") == [
               "/notifications",
               "/users/log-in",
               "/users/register"
             ]
    end
  end

  describe "GET /users/settings" do
    test "rejects an unconfirmed user's session", %{conn: conn} do
      user = unconfirmed_user_fixture()
      conn = conn |> log_in_user(user) |> get("/users/settings")

      assert redirected_to(conn) == "/users/log-in"
    end

    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      response = html_response(conn, 200)
      assert response =~ "Settings"
      document = LazyHTML.from_document(response)

      assert LazyHTML.query(document, "#update_password_password-toggle[type='button']")
             |> Enum.count() == 1

      assert LazyHTML.query(
               document,
               "#update_password_password_confirmation-toggle[type='button']"
             )
             |> Enum.count() == 1
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    @tag token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -11, :minute)
    test "redirects if user is not in sudo mode", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/users/log-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must re-authenticate to access this page."
    end
  end

  describe "PUT /users/settings (change password form)" do
    test "does not set a password for an unconfirmed user's session", %{conn: conn} do
      user = unconfirmed_user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> put("/users/settings", %{
          "action" => "update_password",
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == "/users/log-in"
      assert Accounts.get_user!(user.id).hashed_password == nil
    end

    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_password",
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == ~p"/users/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_password",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      document = LazyHTML.from_document(response)

      assert LazyHTML.query(document, "link[rel='stylesheet'][phx-track-static]") |> Enum.count() ==
               1

      assert LazyHTML.query(document, "script[src][phx-track-static]") |> Enum.count() == 1
      assert response =~ "Settings"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "A link to confirm your email"

      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Settings"
      assert response =~ "must have the @ sign and no spaces"
    end
  end

  describe "GET /users/settings/confirm-email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Email changed successfully"

      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")

      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/settings/confirm-email/oops")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end
end
