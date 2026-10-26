defmodule DailyLogosWeb.PageControllerIntegrationTest do
  use DailyLogosWeb.ConnCase

  alias DailyLogos.Notifications
  alias DailyLogos.Notifications.Subscription
  alias DailyLogos.Repo

  import DailyLogos.AccountsFixtures
  import DailyLogos.NotificationsFixtures
  import DailyLogos.QuotesFixtures

  test "localized home persists the language and both logos link to that home", %{conn: conn} do
    conn = conn |> init_test_session(%{locale: "en"}) |> get("/it")
    document = conn |> html_response(200) |> LazyHTML.from_document()
    assert get_session(conn, :locale) == "it"

    for selector <- [
          "header a:has(img[alt='Daily Logos'])",
          "#mobile-menu a:has(img[alt='Daily Logos'])"
        ] do
      assert LazyHTML.attribute(LazyHTML.query(document, selector), "href") == ["/it/"]
    end

    conn = conn |> recycle() |> get("/")
    assert redirected_to(conn) == "/it"
  end

  test "does not cache session-dependent HTML or replay consumed flash messages", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{"phoenix_flash" => %{"info" => "Account deleted"}})
      |> get("/")

    assert get_resp_header(conn, "cache-control") == ["no-store, private"]
    document = conn |> html_response(200) |> LazyHTML.from_document()
    assert Enum.count(LazyHTML.query(document, "#flash-info")) == 1

    conn = conn |> recycle() |> get("/")
    document = conn |> html_response(200) |> LazyHTML.from_document()
    assert Enum.empty?(LazyHTML.query(document, "#flash-info"))
  end

  describe "notifications" do
    test "keeps the public invitation without creating subscriptions", %{conn: conn} do
      document = conn |> get("/notifications") |> html_response(200) |> LazyHTML.from_document()

      assert Enum.any?(LazyHTML.query(document, "#notifications-register-link"))
      assert Enum.any?(LazyHTML.query(document, "#notifications-login-link"))
      assert Enum.empty?(LazyHTML.query(document, "#email-notification-form"))
      assert Repo.aggregate(Subscription, :count) == 0
    end

    test "loads a disabled email form for authenticated users", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get("/notifications")
      document = conn |> html_response(200) |> LazyHTML.from_document()
      assert Notifications.list_notification_subscriptions(user_scope_fixture(user)) == []

      assert document
             |> LazyHTML.query("#notification-email-address")
             |> LazyHTML.text()
             |> String.trim() == user.email

      assert LazyHTML.attribute(LazyHTML.query(document, "#email-notification-form"), "action") ==
               ["/api/v1/notifications"]

      assert Enum.count(LazyHTML.query(document, "#notification-weekday [data-weekday-toggle]")) ==
               7

      assert Enum.count(LazyHTML.query(document, "#notification-weekday [aria-pressed='false']")) ==
               7

      assert Enum.count(
               LazyHTML.query(document, "#subscription_local_hour-options [role='option']")
             ) == 25

      assert Enum.empty?(LazyHTML.query(document, "#subscription_local_hour-search"))
      assert Enum.empty?(LazyHTML.query(document, "#subscription_language-search"))

      assert LazyHTML.attribute(
               LazyHTML.query(document, "#subscription_timezone-select"),
               "data-suggest-browser"
             ) ==
               ["true"]

      assert Enum.any?(
               LazyHTML.query(
                 document,
                 "#subscription_timezone-options [data-value='Asia/Kathmandu']"
               )
             )

      assert document
             |> LazyHTML.query("#subscription_timezone-options [data-value='Asia/Kathmandu']")
             |> LazyHTML.text()
             |> String.trim() == "Asia/Kathmandu (UTC+05:45)"

      assert Enum.any?(
               LazyHTML.query(document, "#subscription_timezone-trigger[aria-haspopup='listbox']")
             )

      assert Enum.any?(LazyHTML.query(document, "#subscription_timezone-search[role='combobox']"))

      assert Enum.any?(LazyHTML.query(document, "#save-email-notifications[disabled]"))
      assert Enum.empty?(LazyHTML.query(document, "#subscription_enabled[checked]"))
    end

    test "defaults new notification subscriptions to the current site language", %{conn: conn} do
      default_locale =
        Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale)

      for locale <- Gettext.known_locales(DailyLogosWeb.Gettext) do
        user = user_fixture()
        path = if locale == default_locale, do: "/notifications", else: "/#{locale}/notifications"

        response =
          conn
          |> init_test_session(%{locale: locale})
          |> log_in_user(user)
          |> get(path)

        document = response |> html_response(200) |> LazyHTML.from_document()
        assert Notifications.list_notification_subscriptions(user_scope_fixture(user)) == []

        assert LazyHTML.attribute(
                 LazyHTML.query(
                   document,
                   "#subscription_language-options [aria-selected='true']"
                 ),
                 "data-value"
               ) == [locale]
      end
    end

    test "preserves saved notification language and timezone when the site language changes", %{
      conn: conn
    } do
      default_locale =
        Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale)

      for locale <- Gettext.known_locales(DailyLogosWeb.Gettext) -- [default_locale] do
        user = user_fixture()
        scope = user_scope_fixture(user)
        subscription = subscription_fixture(scope, %{enabled: false})

        {:ok, saved} =
          Notifications.update_subscription(scope, subscription, %{
            language: default_locale,
            timezone: "Asia/Kathmandu"
          })

        response = conn |> log_in_user(user) |> get("/#{locale}/notifications")
        document = response |> html_response(200) |> LazyHTML.from_document()

        assert LazyHTML.attribute(
                 LazyHTML.query(
                   document,
                   "#subscription_language-options [aria-selected='true']"
                 ),
                 "data-value"
               ) == [default_locale]

        assert LazyHTML.attribute(LazyHTML.query(document, "#subscription_timezone"), "value") ==
                 ["Asia/Kathmandu"]

        assert Notifications.get_subscription!(scope, subscription.id) == saved
      end
    end

    test "unverified users cannot activate email notifications", %{conn: conn} do
      user = unconfirmed_user_fixture()
      {conn, csrf_token} = notification_form_conn(conn, user)
      assert Notifications.list_notification_subscriptions(user_scope_fixture(user)) == []

      document = conn |> html_response(200) |> LazyHTML.from_document()
      assert Enum.any?(LazyHTML.query(document, "#notification-email-verification"))
      assert Enum.any?(LazyHTML.query(document, "#subscription_enabled[disabled]"))

      conn =
        post_notification_json(
          conn,
          "/api/v1/notifications",
          notification_schedule_params(),
          csrf_token
        )

      assert json_response(conn, 422)["error"]["fields"]["enabled"] != []

      assert Notifications.list_notification_subscriptions(user_scope_fixture(user)) == []
    end

    test "reopening the form never creates a subscription", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get("/notifications")
      assert html_response(conn, 200)
      conn = conn |> recycle() |> put_req_header("accept", "text/html") |> get("/notifications")
      assert html_response(conn, 200)
      assert Notifications.get_email_subscription(user_scope_fixture(user)) == nil
      assert Repo.aggregate(Subscription, :count) == 0
    end

    test "the first Save creates an email subscription using only calendar fields", %{conn: conn} do
      user = user_fixture()
      scope = user_scope_fixture(user)
      {conn, csrf_token} = notification_form_conn(conn, user)

      attrs =
        notification_schedule_params()
        |> Map.merge(%{"provider" => "slack", "name" => "Another channel", "user_id" => "999"})

      assert Repo.aggregate(Subscription, :count) == 0

      conn = post_notification_json(conn, "/api/v1/notifications", attrs, csrf_token)
      response = json_response(conn, 201)
      subscription = Notifications.get_email_subscription(scope)
      assert response["data"]["id"] == subscription.id
      assert response["data"]["provider"] == "email"
      assert subscription.provider == "email"
      assert subscription.user_id == user.id
      assert subscription.name == nil
      assert subscription.enabled == true
      assert subscription.weekdays == [1, 7]
      assert subscription.local_hour == 9
      assert subscription.timezone == "Asia/Kathmandu"
      assert Repo.aggregate(Subscription, :count) == 1

      conn =
        conn
        |> recycle()
        |> put_req_header("accept", "text/html")
        |> get("/notifications")

      document = conn |> html_response(200) |> LazyHTML.from_document()

      assert LazyHTML.attribute(LazyHTML.query(document, "#email-notification-form"), "action") ==
               ["/api/v1/notifications/#{subscription.id}"]
    end

    test "an invalid first Save preserves the draft without inserting a subscription", %{
      conn: conn
    } do
      user = user_fixture()
      {conn, csrf_token} = notification_form_conn(conn, user)
      attrs = Map.put(notification_schedule_params(), "timezone", "Invalid/Timezone")
      conn = post_notification_json(conn, "/api/v1/notifications", attrs, csrf_token)
      response = json_response(conn, 422)

      assert response["error"]["fields"]["timezone"] != []

      assert Repo.aggregate(Subscription, :count) == 0
    end

    test "a repeated first Save does not create a duplicate subscription", %{conn: conn} do
      user = user_fixture()
      {conn, csrf_token} = notification_form_conn(conn, user)

      conn =
        post_notification_json(
          conn,
          "/api/v1/notifications",
          notification_schedule_params(),
          csrf_token
        )

      assert json_response(conn, 201)
      original = Notifications.get_email_subscription(user_scope_fixture(user))

      conn =
        post_notification_json(
          conn,
          "/api/v1/notifications",
          notification_schedule_params(),
          csrf_token
        )

      assert json_response(conn, 422)["error"]["fields"]["user_id"] != []
      assert Repo.aggregate(Subscription, :count) == 1
      assert Notifications.get_email_subscription(user_scope_fixture(user)) == original
    end

    test "saving requires authentication", %{conn: conn} do
      conn =
        post_notification_json(conn, "/api/v1/notifications", notification_schedule_params(), nil)

      assert json_response(conn, 401)["error"]["code"] == "unauthenticated"
      assert Repo.aggregate(Subscription, :count) == 0
    end

    test "JSON saves require a valid browser CSRF token", %{conn: conn} do
      user = user_fixture()
      {conn, _csrf_token} = notification_form_conn(conn, user)

      assert_error_sent 403, fn ->
        post_notification_json(
          conn,
          "/api/v1/notifications",
          notification_schedule_params(),
          "invalid-csrf-token"
        )
      end

      assert Repo.aggregate(Subscription, :count) == 0
    end

    test "saves the calendar and preserves connection fields", %{conn: conn} do
      user = user_fixture()
      scope = user_scope_fixture(user)
      subscription = subscription_fixture(scope, %{enabled: false})
      {conn, csrf_token} = notification_form_conn(conn, user)

      attrs =
        notification_schedule_params()
        |> Map.merge(%{"provider" => "slack", "name" => "Another channel", "user_id" => "999"})

      conn =
        post_notification_json(
          conn,
          "/api/v1/notifications/#{subscription.id}",
          attrs,
          csrf_token
        )

      response = json_response(conn, 200)

      saved = Notifications.get_subscription!(scope, subscription.id)
      assert response["data"]["id"] == subscription.id
      assert saved.enabled == true
      assert saved.weekdays == [1, 7]
      assert saved.local_hour == 9
      assert saved.timezone == "Asia/Kathmandu"
      assert saved.provider == "email"
      assert saved.name == nil
      assert saved.user_id == user.id
    end

    test "renders errors while preserving the submitted schedule", %{conn: conn} do
      user = user_fixture()
      scope = user_scope_fixture(user)
      subscription = subscription_fixture(scope, %{enabled: false})
      {conn, csrf_token} = notification_form_conn(conn, user)
      attrs = Map.put(notification_schedule_params(), "timezone", "Invalid/Timezone")

      conn =
        post_notification_json(
          conn,
          "/api/v1/notifications/#{subscription.id}",
          attrs,
          csrf_token
        )

      response = json_response(conn, 422)

      assert response["error"]["fields"]["timezone"] != []
      assert Notifications.get_subscription!(scope, subscription.id) == subscription
    end

    test "can clear weekdays while disabling the schedule", %{conn: conn} do
      user = user_fixture()
      scope = user_scope_fixture(user)

      {:ok, subscription} =
        Notifications.create_subscription(scope, %{
          provider: "email",
          enabled: true,
          weekdays: [1],
          local_hour: 9,
          timezone: "Etc/UTC",
          language: notification_schedule_params()["language"]
        })

      {conn, csrf_token} = notification_form_conn(conn, user)

      attrs =
        Map.merge(notification_schedule_params(), %{"enabled" => "false", "weekdays" => [""]})

      conn =
        post_notification_json(
          conn,
          "/api/v1/notifications/#{subscription.id}",
          attrs,
          csrf_token
        )

      assert json_response(conn, 200)
      saved = Notifications.get_subscription!(scope, subscription.id)
      assert saved.weekdays == []
      assert saved.enabled == false
    end

    test "cannot save another user's subscription", %{conn: conn} do
      owner_scope = user_scope_fixture()
      subscription = subscription_fixture(owner_scope, %{enabled: false})
      other_user = user_fixture()
      {conn, csrf_token} = notification_form_conn(conn, other_user)

      conn =
        post_notification_json(
          conn,
          "/api/v1/notifications/#{subscription.id}",
          notification_schedule_params(),
          csrf_token
        )

      assert json_response(conn, 404)

      assert Notifications.get_subscription!(owner_scope, subscription.id) == subscription
    end

    test "uses canonical save routes and preserves the current locale after saving", %{conn: conn} do
      default_locale =
        Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale)

      for locale <- Gettext.known_locales(DailyLogosWeb.Gettext) -- [default_locale] do
        user = user_fixture()
        conn = conn |> log_in_user(user) |> get("/#{locale}/notifications")
        document = conn |> html_response(200) |> LazyHTML.from_document()
        assert Notifications.list_notification_subscriptions(user_scope_fixture(user)) == []

        csrf_token =
          document
          |> LazyHTML.query("input[name='_csrf_token']")
          |> LazyHTML.attribute("value")
          |> List.first()

        assert LazyHTML.attribute(LazyHTML.query(document, "#email-notification-form"), "action") ==
                 ["/api/v1/notifications"]

        conn =
          post_notification_json(
            conn,
            "/api/v1/notifications",
            notification_schedule_params(),
            csrf_token
          )

        assert json_response(conn, 201)["data"]["language"] ==
                 notification_schedule_params()["language"]
      end
    end
  end

  defp notification_schedule_params do
    %{
      "enabled" => "true",
      "weekdays" => ["", "1", "7"],
      "local_hour" => "9",
      "timezone" => "Asia/Kathmandu",
      "language" => Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale)
    }
  end

  defp notification_form_conn(conn, user, path \\ "/notifications") do
    conn = conn |> log_in_user(user) |> get(path)
    document = conn |> html_response(200) |> LazyHTML.from_document()

    csrf_token =
      document
      |> LazyHTML.query("input[name='_csrf_token']")
      |> LazyHTML.attribute("value")
      |> List.first()

    {conn, csrf_token}
  end

  defp post_notification_json(conn, path, attrs, csrf_token) do
    conn =
      conn
      |> recycle()
      |> Plug.Conn.put_private(:plug_skip_csrf_protection, false)
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    conn =
      if csrf_token do
        put_req_header(conn, "x-csrf-token", csrf_token)
      else
        conn
      end

    post(conn, path, Jason.encode!(%{"subscription" => attrs}))
  end

  describe "GET /:month/:day" do
    test "renders quote page for the 1st of January", %{conn: conn} do
      quote_fixture(%{day: 1, month: 1})
      conn = get(conn, "/1/1")
      assert html_response(conn, 200) =~ "Daily Logos"
    end

    test "renders Italian quote page for the 1st of January", %{conn: conn} do
      quote_fixture(%{day: 1, month: 1})
      conn = get(conn, "/it/1/1")
      assert html_response(conn, 200) =~ "Daily Logos"
    end

    test "renders leap day and includes it in calendar navigation", %{conn: conn} do
      quote_fixture(%{day: 29, month: 2})
      conn = get(conn, "/2/29")
      document = conn |> html_response(200) |> LazyHTML.from_document()

      assert document
             |> LazyHTML.query("a[aria-label='Previous day'][href='/2/28']")
             |> Enum.any?()

      assert document
             |> LazyHTML.query("a[aria-label='Next day'][href='/3/1']")
             |> Enum.any?()

      quote_fixture(%{day: 28, month: 2})
      document = get(conn, "/2/28") |> html_response(200) |> LazyHTML.from_document()

      assert document
             |> LazyHTML.query("a[aria-label='Next day'][href='/2/29']")
             |> Enum.any?()
    end

    test "returns 404 when no quote exists for the given day", %{conn: conn} do
      conn = get(conn, "/13/41")
      assert conn.status == 404
    end

    test "returns 404 when no quote exists for a valid calendar date", %{conn: conn} do
      conn = get(conn, "/2/29")
      assert conn.status == 404
    end
  end
end
