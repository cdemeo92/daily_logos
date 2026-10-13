defmodule DailyLogosWeb.UserPrivacyControllerTest do
  use DailyLogosWeb.ConnCase, async: true

  alias DailyLogos.Accounts
  alias DailyLogos.Accounts.UserToken
  alias DailyLogos.Repo

  setup :register_and_log_in_user

  describe "GET /users/account/privacy" do
    test "renders account deletion confirmation", %{conn: conn} do
      response = conn |> get("/users/account/privacy") |> html_response(200)

      assert response =~ "Privacy"
      assert response =~ "Deleting your account is permanent"
      assert response =~ "delete-account-form"
      assert response =~ "I understand that deleting my account is permanent."
      refute response =~ ~s(id="privacy_confirm" name="privacy[confirm]" value="true" checked)
      assert response =~ ~s(name="robots" content="noindex,nofollow,noarchive")
    end

    test "redirects anonymous users to login" do
      conn = build_conn() |> get("/users/account/privacy")

      assert redirected_to(conn) == "/users/log-in"
      assert get_session(conn, :user_return_to) == "/users/account/privacy"
    end
  end

  describe "DELETE /users/account" do
    test "requires explicit confirmation", %{conn: conn, user: user} do
      conn = delete(conn, "/users/account", %{"privacy" => %{"confirm" => "false"}})

      assert redirected_to(conn) == "/users/account/privacy"
      assert Accounts.get_user!(user.id)
    end

    test "deletes the account and authentication tokens", %{conn: conn, user: user} do
      token = get_session(conn, :user_token)

      conn = delete(conn, "/users/account", %{"privacy" => %{"confirm" => "true"}})

      assert redirected_to(conn) == "/"
      assert is_nil(Repo.get(DailyLogos.Accounts.User, user.id))
      assert Repo.all_by(UserToken, user_id: user.id) == []
      assert is_nil(get_session(conn, :user_token))
      assert Accounts.delete_user_session_token(token) == :ok
    end

    @tag token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -11, :minute)
    test "requires recent authentication before deleting", %{conn: conn, user: user} do
      conn = delete(conn, "/users/account", %{"privacy" => %{"confirm" => "true"}})

      assert redirected_to(conn) == "/users/log-in"
      assert get_session(conn, :user_return_to) == "/users/account/privacy"
      assert Accounts.get_user!(user.id)
    end
  end
end
