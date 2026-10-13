defmodule DailyLogosWeb.UserRegistrationControllerTest do
  use DailyLogosWeb.ConnCase, async: true

  alias DailyLogos.Accounts
  import DailyLogos.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      response = html_response(conn, 200)
      assert response =~ "Register"
      assert response =~ ~p"/users/log-in"
      assert response =~ ~p"/users/register"
    end

    test "does not add a Notifications promo block to registration", %{conn: conn} do
      response = conn |> get("/users/register") |> html_response(200)
      refute response =~ "Quote notifications"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(~p"/users/register")

      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "POST /users/register" do
    test "throttles repeated registration attempts", %{conn: conn} do
      email = unique_user_email()

      responses =
        for _attempt <- 1..6 do
          post(conn, "/users/register", %{"user" => %{"email" => email}})
        end

      assert Enum.map(responses, & &1.status) == [302, 200, 200, 200, 200, 429]
      assert Plug.Conn.get_resp_header(List.last(responses), "retry-after") != []
    end

    @tag :capture_log
    test "creates account but does not log in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, ~p"/users/register", %{
          "user" => valid_user_attributes(email: email)
        })

      refute get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/users/log-in"

      assert conn.assigns.flash["info"] =~
               ~r/An email was sent to .*, please access it to confirm your account/
    end

    @tag :capture_log
    test "preserves Notifications through registration and email confirmation", %{conn: conn} do
      conn = get(conn, "/users/register?return_to=%2Fnotifications")
      assert html_response(conn, 200) =~ "Register for an account"
      assert get_session(conn, :user_return_to) == "/notifications"

      email = unique_user_email()

      conn =
        post(conn, ~p"/users/register", %{
          "user" => valid_user_attributes(email: email)
        })

      assert redirected_to(conn) == ~p"/users/log-in"
      user = Accounts.get_user_by_email(email)

      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert redirected_to(conn) == "/notifications"
      assert conn |> get("/notifications") |> html_response(200) =~ "Coming soon"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, ~p"/users/register", %{
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Register"
      assert response =~ "must have the @ sign and no spaces"
    end
  end
end
