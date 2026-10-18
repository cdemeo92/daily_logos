defmodule DailyLogosWeb.OAuthControllerTest do
  use DailyLogosWeb.ConnCase, async: false

  import DailyLogos.AccountsFixtures

  alias DailyLogos.Accounts
  alias DailyLogos.Accounts.{User, UserIdentity, UserToken}
  alias DailyLogos.Repo
  alias Ueberauth.Auth
  alias Ueberauth.Auth.{Extra, Info}

  @oauth_modules %{
    google: Ueberauth.Strategy.Google.OAuth,
    github: Ueberauth.Strategy.Github.OAuth,
    facebook: Ueberauth.Strategy.Facebook.OAuth
  }

  setup do
    previous_configs =
      Map.new(@oauth_modules, fn {provider, module} ->
        {provider, Application.get_env(:ueberauth, module)}
      end)

    Enum.each(@oauth_modules, fn {_provider, module} ->
      Application.put_env(:ueberauth, module,
        client_id: "test-client-id",
        client_secret: "test-client-secret"
      )
    end)

    on_exit(fn ->
      Enum.each(previous_configs, fn {provider, config} ->
        module = Map.fetch!(@oauth_modules, provider)

        if is_nil(config) do
          Application.delete_env(:ueberauth, module)
        else
          Application.put_env(:ueberauth, module, config)
        end
      end)
    end)

    :ok
  end

  describe "GET /auth/:provider" do
    test "renders configured providers and marks the last used provider on login", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{last_oauth_provider: "google"})
        |> get("/users/log-in")

      response = html_response(conn, 200)

      assert response =~ ~s(id="oauth-login-google")
      assert response =~ ~s(id="oauth-login-github")
      assert response =~ ~s(id="oauth-login-facebook")
      assert response =~ ~s(id="oauth-last-used-google")
      refute response =~ ~s(id="oauth-last-used-github")
    end

    test "renders connected and available providers in account settings", %{conn: conn} do
      user = user_fixture()
      {:ok, _identity} = Accounts.link_oauth_identity(user, "google", "google-connected")

      conn = conn |> log_in_user(user) |> get("/users/settings")
      response = html_response(conn, 200)

      assert response =~ ~s(id="oauth-settings-google")
      assert response =~ "Connected"
      assert response =~ ~s(id="oauth-settings-github")
      assert response =~ "Connect GitHub"
      assert response =~ ~s(id="oauth-settings-facebook")
      assert response =~ "Connect Facebook"
    end

    test "starts OAuth and preserves the localized request locale in the session", %{conn: conn} do
      conn = get(conn, "/it/auth/google")
      authorization_url = URI.parse(redirected_to(conn))
      callback_url = authorization_url.query |> URI.decode_query() |> Map.fetch!("redirect_uri")

      assert authorization_url.host == "accounts.google.com"
      assert callback_url =~ "/auth/google/callback"
      refute callback_url =~ "/it/auth/google/callback"
      assert get_session(conn, :locale) == "it"
    end

    test "does not start an unconfigured provider", %{conn: conn} do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
        client_id: "",
        client_secret: nil
      )

      conn = get(conn, "/auth/google")

      assert redirected_to(conn) == "/users/log-in"
      refute get_session(conn, :user_token)
    end

    test "does not silently link when an authenticated user visits the login endpoint", %{
      conn: conn
    } do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get("/auth/google")

      assert redirected_to(conn) == "/users/settings"
      refute Repo.get_by(UserIdentity, user_id: user.id, provider: "google")
    end

    test "requires authentication before starting an account link", %{conn: conn} do
      conn = post(conn, "/users/settings/identities/github")

      assert redirected_to(conn) == "/users/log-in"
    end

    test "requires recent authentication before starting an account link", %{conn: conn} do
      authenticated_at = DateTime.add(DateTime.utc_now(:second), -11, :minute)

      conn =
        conn
        |> log_in_user(user_fixture(), token_authenticated_at: authenticated_at)
        |> post("/users/settings/identities/github")

      assert redirected_to(conn) == "/users/log-in"
    end

    test "canonicalizes the default English locale prefix", %{conn: conn} do
      assert redirected_to(get(conn, "/en/auth/google")) == "/auth/google"
    end

    test "returns 404 for unsupported locale prefixes", %{conn: conn} do
      assert conn |> get("/fr/auth/google") |> response(404)
    end
  end

  describe "GET /auth/:provider/callback" do
    test "redirects provider failures to the localized login route", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{locale: "it"})
        |> get("/auth/google/callback")

      assert redirected_to(conn) == "/it/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error)
      refute get_session(conn, :user_token)
    end

    test "clears a pending link marker when the provider callback fails", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> Plug.Conn.put_session(:oauth_link_user_id, user.id)
        |> get("/auth/google/callback")

      assert redirected_to(conn) == "/users/settings"
      refute get_session(conn, :oauth_link_user_id)
    end

    test "logs in an existing linked identity even when the provider omits email", %{conn: conn} do
      user = user_fixture()
      {:ok, _identity} = Accounts.link_oauth_identity(user, "google", "google-subject")

      auth = oauth_auth(:google, "google-subject", nil, nil)

      conn =
        conn
        |> init_test_session(%{locale: "it"})
        |> Plug.Conn.assign(:ueberauth_auth, auth)
        |> get("/auth/google/callback")

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"
      assert get_session(conn, :locale) == "it"
    end

    test "registers and logs in a new account when Google verifies its email", %{conn: conn} do
      email = unique_user_email()
      auth = oauth_auth(:google, "google-new-user", email, true)
      conn = conn |> Plug.Conn.assign(:ueberauth_auth, auth) |> get("/auth/google/callback")

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"
      assert %User{confirmed_at: confirmed_at} = Accounts.get_user_by_email(email)
      assert confirmed_at

      assert %UserIdentity{provider_uid: "google-new-user"} =
               DailyLogos.Repo.get_by!(UserIdentity, provider: "google")

      conn = conn |> recycle() |> get("/users/settings")
      document = conn |> html_response(200) |> LazyHTML.from_document()
      assert Enum.count(LazyHTML.query(document, "#oauth-settings-google .badge")) == 1
      assert Enum.empty?(LazyHTML.query(document, "#oauth-connect-form-google"))
    end

    test "requires local email verification before using an unverified provider email", %{
      conn: conn
    } do
      email = unique_user_email()
      auth = oauth_auth(:facebook, "facebook-new-user", email, false)
      conn = conn |> Plug.Conn.assign(:ueberauth_auth, auth) |> get("/auth/facebook/callback")

      refute get_session(conn, :user_token)
      assert redirected_to(conn) == "/users/verify-email"
      user = Accounts.get_user_by_email(email)
      refute user.confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id, context: "login")
      refute Repo.get_by(UserIdentity, provider: "facebook", provider_uid: "facebook-new-user")

      conn = conn |> recycle() |> get("/users/verify-email")
      document = conn |> html_response(200) |> LazyHTML.from_document()
      assert Enum.count(LazyHTML.query(document, "#email-verification-status")) == 1
      conn = conn |> recycle() |> get("/users/verify-email")
      assert html_response(conn, 200) =~ "Verify your email to sign in"

      token = extract_user_token(&Accounts.deliver_login_instructions(user, &1))
      conn = post(conn, "/users/log-in", %{"user" => %{"token" => token}})
      assert get_session(conn, :user_token)
      assert Accounts.get_user!(user.id).confirmed_at
      refute Accounts.get_user_by_oauth_identity("facebook", "facebook-new-user")
    end

    test "registration reuses the social controls", %{conn: conn} do
      document =
        conn |> get("/it/users/register") |> html_response(200) |> LazyHTML.from_document()

      assert Enum.count(LazyHTML.query(document, "#oauth-login-google")) == 1
      assert Enum.count(LazyHTML.query(document, "#oauth-login-github")) == 1

      assert LazyHTML.attribute(LazyHTML.query(document, "#oauth-login-google"), "href") == [
               "/it/auth/google"
             ]
    end

    test "does not register or link an existing email without local authentication", %{conn: conn} do
      user = unconfirmed_user_fixture()
      auth = oauth_auth(:facebook, "untrusted-existing-email", user.email, false)
      conn = conn |> assign(:ueberauth_auth, auth) |> get("/auth/facebook/callback")
      assert redirected_to(conn) == "/users/log-in"
      refute get_session(conn, :user_token)
      refute Repo.get_by(UserToken, user_id: user.id)
      refute Repo.get_by(UserIdentity, user_id: user.id)
    end

    test "uses the selected locale for local verification after OAuth", %{conn: conn} do
      auth = oauth_auth(:facebook, "italian-new-user", unique_user_email(), false)

      conn =
        conn
        |> init_test_session(%{locale: "it"})
        |> assign(:ueberauth_auth, auth)
        |> get("/auth/facebook/callback")

      assert redirected_to(conn) == "/it/users/verify-email"
      conn = conn |> recycle() |> get("/it/users/verify-email")
      document = conn |> html_response(200) |> LazyHTML.from_document()
      assert Enum.count(LazyHTML.query(document, "#email-verification-status")) == 1

      assert LazyHTML.attribute(LazyHTML.query(document, "#verification-back-to-login"), "href") ==
               ["/it/users/log-in"]
    end

    test "registration hides unconfigured social providers on initial and invalid submissions", %{
      conn: conn
    } do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
        client_id: "",
        client_secret: ""
      )

      conn = get(conn, "/users/register")
      document = conn |> html_response(200) |> LazyHTML.from_document()
      assert Enum.empty?(LazyHTML.query(document, "#oauth-login-google"))
      conn = post(conn, "/users/register", %{"user" => %{"email" => "invalid"}})
      document = conn |> html_response(200) |> LazyHTML.from_document()
      assert Enum.empty?(LazyHTML.query(document, "#oauth-login-google"))
      assert Enum.count(LazyHTML.query(document, "#oauth-login-github")) == 1
    end

    test "requires a local account when the provider omits email", %{conn: conn} do
      auth = oauth_auth(:google, "google-without-email", nil, nil)

      conn =
        conn
        |> Plug.Conn.assign(:ueberauth_auth, auth)
        |> get("/auth/google/callback")

      assert redirected_to(conn) == "/users/register"
      refute get_session(conn, :pending_oauth_identity)
      refute Accounts.get_user_by_oauth_identity("google", "google-without-email")

      conn = conn |> recycle() |> get("/it/users/register")
      email = unique_user_email()
      conn = post(conn, "/users/register", %{"user" => %{"email" => email}})
      assert redirected_to(conn) == "/it/users/verify-email"
      refute Accounts.get_user_by_email(email).confirmed_at
      refute Accounts.get_user_by_oauth_identity("google", "google-without-email")
    end

    test "does not silently link a provider identity to an existing email", %{conn: conn} do
      user = user_fixture()
      auth = oauth_auth(:google, "google-existing-email", user.email, true)
      conn = conn |> Plug.Conn.assign(:ueberauth_auth, auth) |> get("/auth/google/callback")

      refute get_session(conn, :user_token)
      assert redirected_to(conn) == "/users/log-in"
      refute Repo.get_by(UserIdentity, provider: "google", provider_uid: "google-existing-email")
    end

    test "does not link a provider identity from the public login callback", %{conn: conn} do
      user = user_fixture()
      auth = oauth_auth(:github, "github-linked-account", unique_user_email(), true)

      conn =
        conn
        |> log_in_user(user)
        |> Plug.Conn.assign(:ueberauth_auth, auth)
        |> get("/auth/github/callback")

      assert redirected_to(conn) == "/users/settings"
      refute Repo.get_by(UserIdentity, user_id: user.id, provider: "github")
    end

    test "links a provider through the authenticated sudo endpoint", %{conn: conn} do
      user = user_fixture()
      provider_uid = "github-linked-#{System.unique_integer([:positive])}"

      refute Repo.get_by(UserIdentity, provider: "github", provider_uid: provider_uid)

      conn =
        conn
        |> log_in_user(user, token_authenticated_at: DateTime.utc_now(:second))
        |> post("/users/settings/identities/github")

      assert redirected_to(conn) =~ "https://github.com/login/oauth/authorize"
      assert get_session(conn, :oauth_link_user_id) == user.id

      auth = oauth_auth(:github, provider_uid, nil, nil)

      conn =
        conn
        |> recycle()
        |> Plug.Conn.assign(:ueberauth_auth, auth)
        |> get("/auth/github/callback")

      assert redirected_to(conn) == "/users/settings"
      assert conn.assigns.current_scope.user.id == user.id
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == nil
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Sign-in provider connected."

      assert Repo.get_by!(UserIdentity,
               user_id: user.id,
               provider: "github",
               provider_uid: provider_uid
             )

      assert Accounts.get_user!(user.id).email == user.email
      refute get_session(conn, :oauth_link_user_id)
    end
  end

  defp oauth_auth(provider, uid, email, email_verified?) do
    raw_user =
      case provider do
        :google ->
          %{"email_verified" => email_verified?}

        :github ->
          %{"emails" => [%{"email" => email, "primary" => true, "verified" => email_verified?}]}

        :facebook ->
          %{"verified" => email_verified?}
      end

    %Auth{
      uid: uid,
      provider: provider,
      info: %Info{email: email, name: "OAuth Test User"},
      extra: %Extra{raw_info: %{user: raw_user}}
    }
  end
end
