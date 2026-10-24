defmodule DailyLogos.NotificationsTest do
  use DailyLogos.DataCase

  alias DailyLogos.Notifications
  alias DailyLogos.Notifications.Subscription

  import DailyLogos.AccountsFixtures,
    only: [user_scope_fixture: 0, user_scope_fixture: 1, unconfirmed_user_fixture: 0]

  import DailyLogos.NotificationsFixtures

  @invalid_attrs %{
    enabled: nil,
    name: nil,
    language: nil,
    provider: nil,
    weekdays: nil,
    local_hour: nil,
    timezone: nil
  }

  describe "notification_subscriptions" do
    test "list_notification_subscriptions/1 returns all scoped notification_subscriptions" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      other_subscription = subscription_fixture(other_scope)

      assert Notifications.list_notification_subscriptions(scope) == [subscription]
      assert Notifications.list_notification_subscriptions(other_scope) == [other_subscription]
    end

    test "list_notification_subscriptions/1 puts email before previously created channels" do
      scope = user_scope_fixture()
      channel = subscription_fixture(scope, %{provider: "slack", name: "Daily quotes"})
      email = subscription_fixture(scope)

      assert Notifications.list_notification_subscriptions(scope) == [email, channel]
    end

    test "get_subscription!/2 returns the subscription with given id" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      other_scope = user_scope_fixture()

      assert Notifications.get_subscription!(scope, subscription.id) == subscription

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_subscription!(other_scope, subscription.id)
      end
    end

    test "create_subscription/2 with valid data creates a subscription" do
      valid_attrs = %{
        enabled: true,
        language: Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale),
        provider: "email",
        weekdays: [1, 2],
        local_hour: 9,
        timezone: "Etc/UTC"
      }

      scope = user_scope_fixture()

      assert {:ok, %Subscription{} = subscription} =
               Notifications.create_subscription(scope, valid_attrs)

      assert subscription.enabled == true
      assert subscription.name == nil
      assert subscription.language == valid_attrs.language
      assert subscription.provider == "email"
      assert subscription.weekdays == [1, 2]
      assert subscription.local_hour == 9
      assert subscription.timezone == "Etc/UTC"
      assert subscription.user_id == scope.user.id
    end

    test "create_subscription/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Notifications.create_subscription(scope, @invalid_attrs)
    end

    test "update_subscription/3 with valid data updates the subscription" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      update_attrs = %{
        enabled: false,
        weekdays: [1],
        local_hour: 10,
        timezone: "Europe/Rome"
      }

      assert {:ok, %Subscription{} = updated} =
               Notifications.update_subscription(scope, subscription, update_attrs)

      assert updated.enabled == false
      assert updated.language == subscription.language
      assert updated.provider == subscription.provider
      assert updated.weekdays == [1]
      assert updated.local_hour == 10
      assert updated.timezone == "Europe/Rome"
      assert updated.user_id == scope.user.id
      assert Notifications.get_subscription!(scope, subscription.id) == updated
    end

    test "update_subscription/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert_raise MatchError, fn ->
        Notifications.update_subscription(other_scope, subscription, %{})
      end
    end

    test "update_subscription/3 cannot change connection fields or ownership" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      attrs = %{
        "provider" => "slack",
        "name" => "Another channel",
        "user_id" => scope.user.id + 1,
        "local_hour" => 10
      }

      assert {:ok, updated} = Notifications.update_subscription(scope, subscription, attrs)
      assert updated.provider == "email"
      assert updated.name == subscription.name
      assert updated.user_id == scope.user.id
      assert updated.local_hour == 10

      assert {:error, :email_subscription_not_deletable} =
               Notifications.delete_subscription(scope, updated)

      assert Notifications.get_subscription!(scope, subscription.id) == updated
    end

    test "unverified users cannot create or enable active email subscriptions" do
      scope = user_scope_fixture(unconfirmed_user_fixture())

      attrs = %{
        provider: "email",
        enabled: true,
        weekdays: [1],
        local_hour: 9,
        timezone: "Etc/UTC",
        language: Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale)
      }

      assert {:error, created} = Notifications.create_subscription(scope, attrs)
      assert Keyword.has_key?(created.errors, :enabled)

      subscription = subscription_fixture(scope, %{enabled: false})

      assert {:error, updated} =
               Notifications.update_subscription(scope, subscription, %{enabled: true})

      assert Keyword.has_key?(updated.errors, :enabled)
      assert Notifications.get_subscription!(scope, subscription.id).enabled == false
    end

    test "update_subscription/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_subscription(scope, subscription, @invalid_attrs)

      assert subscription == Notifications.get_subscription!(scope, subscription.id)
    end

    test "delete_subscription/2 deletes Slack and Discord subscriptions" do
      scope = user_scope_fixture()

      for provider <- ["slack", "discord"] do
        subscription = subscription_fixture(scope, %{provider: provider, name: "Daily quotes"})
        assert {:ok, %Subscription{}} = Notifications.delete_subscription(scope, subscription)

        assert_raise Ecto.NoResultsError, fn ->
          Notifications.get_subscription!(scope, subscription.id)
        end
      end
    end

    test "delete_subscription/2 preserves email subscriptions whether enabled or disabled" do
      for enabled <- [true, false] do
        scope = user_scope_fixture()
        subscription = subscription_fixture(scope, %{enabled: enabled})

        assert {:error, :email_subscription_not_deletable} =
                 Notifications.delete_subscription(scope, subscription)

        assert Notifications.get_subscription!(scope, subscription.id) == subscription
      end
    end

    test "delete_subscription/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()

      for provider <- ["email", "slack", "discord"] do
        subscription = subscription_fixture(scope, %{provider: provider, name: "Daily quotes"})

        assert_raise MatchError, fn ->
          Notifications.delete_subscription(other_scope, subscription)
        end

        assert Notifications.get_subscription!(scope, subscription.id) == subscription
      end
    end

    test "change_subscription/2 returns a subscription changeset" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert %Ecto.Changeset{} = Notifications.change_subscription(scope, subscription)
    end

    test "change_subscription/3 changes only the calendar and does not save" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      changeset =
        Notifications.change_subscription(scope, subscription, %{
          provider: "slack",
          name: "Another channel",
          local_hour: 10
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :provider) == "email"
      assert Ecto.Changeset.get_field(changeset, :name) == subscription.name
      assert Ecto.Changeset.get_field(changeset, :local_hour) == 10
      assert Notifications.get_subscription!(scope, subscription.id) == subscription
    end

    test "change_subscription/3 rejects another user's subscription" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert_raise MatchError, fn ->
        Notifications.change_subscription(other_scope, subscription, %{local_hour: 10})
      end

      assert Notifications.get_subscription!(scope, subscription.id) == subscription
    end
  end

  describe "ensure_email_subscription/1" do
    test "creates a disabled email subscription for an unverified user without opting in" do
      scope = user_scope_fixture(unconfirmed_user_fixture())

      assert {:ok, subscription} = Notifications.ensure_email_subscription(scope)
      assert subscription.provider == "email"
      assert subscription.user_id == scope.user.id
      assert subscription.enabled == false
      assert subscription.weekdays == nil
      assert subscription.local_hour == nil
      assert subscription.timezone == nil

      assert subscription.language ==
               Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale)

      assert Notifications.list_notification_subscriptions(scope) == [subscription]
    end

    test "repeated calls preserve an existing enabled schedule" do
      scope = user_scope_fixture()
      existing = subscription_fixture(scope)

      assert {:ok, ^existing} = Notifications.ensure_email_subscription(scope)
      assert {:ok, ^existing} = Notifications.ensure_email_subscription(scope)
      assert Notifications.list_notification_subscriptions(scope) == [existing]
    end

    test "repeated calls create only one row and keep users isolated" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()

      assert {:ok, subscription} = Notifications.ensure_email_subscription(scope)
      assert {:ok, ^subscription} = Notifications.ensure_email_subscription(scope)
      assert {:ok, other_subscription} = Notifications.ensure_email_subscription(other_scope)
      assert subscription.id != other_subscription.id
      assert Notifications.list_notification_subscriptions(scope) == [subscription]
      assert Notifications.list_notification_subscriptions(other_scope) == [other_subscription]
    end
  end
end
