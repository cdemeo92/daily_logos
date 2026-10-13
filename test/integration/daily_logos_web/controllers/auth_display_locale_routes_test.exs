defmodule DailyLogosWeb.AuthDisplayLocaleRoutesTest do
  use DailyLogosWeb.ConnCase, async: true

  import DailyLogos.AccountsFixtures

  alias DailyLogos.Accounts

  describe "localized auth display routes" do
    test "renders the notification signup landing in Italian for anonymous users", %{conn: conn} do
      conn = get(conn, "/it/notifications")
      response = html_response(conn, 200)

      assert response =~ "Vuoi ricevere la citazione del giorno e lasciarti ispirare?"

      assert response =~
               "Crea un account e preparati a scegliere quando e come ricevere la citazione quotidiana."

      assert response =~ ~s(class="btn btn-primary min-h-11")
      refute response =~ "Le impostazioni delle notifiche sono in arrivo."
      assert response =~ "Notifiche"
      refute response =~ "notifications-coming-soon"
      assert conn.assigns.locale == "it"
    end

    test "renders the login page in Italian", %{conn: conn} do
      conn = get(conn, "/it/users/log-in")

      assert html_response(conn, 200) =~ "Accedi"
      assert html_response(conn, 200) =~ ~s(name="robots" content="index,follow")
      assert conn.assigns.locale == "it"
    end

    test "renders a magic-link confirmation page in Italian", %{conn: conn} do
      user = unconfirmed_user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      conn = get(conn, "/it/users/log-in/#{token}")

      assert html_response(conn, 200) =~ "Conferma e resta connesso"
      assert html_response(conn, 200) =~ ~s(name="robots" content="noindex,nofollow,noarchive")
      assert conn.assigns.locale == "it"
    end

    test "renders registration in Italian", %{conn: conn} do
      conn = get(conn, "/it/users/register")

      assert html_response(conn, 200) =~ "Crea un account"
      assert html_response(conn, 200) =~ ~s(name="robots" content="index,follow")
      assert conn.assigns.locale == "it"
    end

    test "renders settings in Italian for an authenticated user", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get("/it/users/settings")

      assert html_response(conn, 200) =~ "Impostazioni account"
      assert html_response(conn, 200) =~ ~s(name="robots" content="noindex,follow")
      assert conn.assigns.locale == "it"
    end

    test "renders Notifications coming soon for an authenticated user", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get("/it/notifications")
      response = html_response(conn, 200)

      assert response =~ "Notifiche"
      assert response =~ "In arrivo"
      assert response =~ "Le impostazioni delle notifiche non sono ancora disponibili."
      assert conn.assigns.locale == "it"
    end

    test "renders account privacy and deletion in Italian", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get("/it/users/account/privacy")
      response = html_response(conn, 200)

      assert response =~ "Privacy"
      assert response =~ "Elimina definitivamente l&#39;account"
      assert response =~ "aria-pressed=\"true\""
      assert response =~ ~s(name="robots" content="noindex,nofollow,noarchive")
      assert conn.assigns.locale == "it"
    end
  end

  describe "canonical English auth display routes" do
    test "redirects the prefixed login route to its canonical URL", %{conn: conn} do
      assert redirected_to(get(conn, "/en/users/log-in")) == "/users/log-in"
    end

    test "redirects the prefixed magic-link route to its canonical URL", %{conn: conn} do
      assert redirected_to(get(conn, "/en/users/log-in/token")) == "/users/log-in/token"
    end

    test "redirects the prefixed registration route to its canonical URL", %{conn: conn} do
      assert redirected_to(get(conn, "/en/users/register")) == "/users/register"
    end

    test "redirects the prefixed settings route to its canonical URL", %{conn: conn} do
      assert redirected_to(get(conn, "/en/users/settings")) == "/users/settings"
    end
  end

  describe "unsupported auth display routes" do
    test "returns 404 for an unsupported login prefix", %{conn: conn} do
      assert conn |> get("/fr/users/log-in") |> response(404)
    end

    test "returns 404 for an unsupported magic-link prefix", %{conn: conn} do
      assert conn |> get("/fr/users/log-in/token") |> response(404)
    end

    test "returns 404 for an unsupported registration prefix", %{conn: conn} do
      assert conn |> get("/fr/users/register") |> response(404)
    end

    test "returns 404 for an unsupported settings prefix", %{conn: conn} do
      assert conn |> get("/fr/users/settings") |> response(404)
    end
  end
end
