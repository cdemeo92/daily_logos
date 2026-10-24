defmodule DailyLogos.Notifications.SubscriptionTest do
  use ExUnit.Case, async: true

  alias DailyLogos.Accounts.{Scope, User}
  alias DailyLogos.Notifications.Subscription

  @schedule %{
    provider: "email",
    enabled: true,
    weekdays: [1, 3, 5],
    local_hour: 9,
    timezone: "Etc/UTC",
    language: "en"
  }

  setup_all do
    if Process.whereis(Tzdata.EtsHolder) == nil do
      start_supervised!(Tzdata.EtsHolder)
    end

    :ok
  end

  setup do
    %{scope: Scope.for_user(%User{id: 1, confirmed_at: ~U[2026-10-24 00:00:00Z]})}
  end

  describe "changeset/3" do
    test "accepts a disabled email subscription without a name or schedule", %{scope: scope} do
      changeset = Subscription.changeset(%Subscription{}, %{provider: "email"}, scope)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :enabled) == false
      assert Ecto.Changeset.get_field(changeset, :user_id) == scope.user.id
    end

    test "assigns ownership from the scope rather than submitted attributes", %{scope: scope} do
      attrs = %{"provider" => "email", "user_id" => 999}
      changeset = Subscription.changeset(%Subscription{}, attrs, scope)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :user_id) == scope.user.id
    end

    test "requires a supported provider", %{scope: scope} do
      missing = Subscription.changeset(%Subscription{}, %{}, scope)
      unsupported = Subscription.changeset(%Subscription{}, %{provider: "unsupported"}, scope)

      assert_error(missing, :provider, :required)
      assert_error(unsupported, :provider, :inclusion)
    end

    test "rejects an explicitly missing enabled state", %{scope: scope} do
      changeset =
        Subscription.changeset(%Subscription{}, %{provider: "email", enabled: nil}, scope)

      assert_error(changeset, :enabled, :required)
    end

    test "accepts a complete enabled schedule", %{scope: scope} do
      changeset = Subscription.changeset(%Subscription{}, @schedule, scope)

      assert changeset.valid?
    end

    test "accepts every language supported by Gettext", %{scope: scope} do
      languages = Gettext.known_locales(DailyLogosWeb.Gettext)
      assert languages != []

      for language <- languages do
        attrs = %{@schedule | language: language}
        changeset = Subscription.changeset(%Subscription{}, attrs, scope)

        assert changeset.valid?
        assert Ecto.Changeset.get_field(changeset, :language) == language
      end
    end

    test "rejects unsupported languages even when disabled", %{scope: scope} do
      for enabled <- [true, false] do
        attrs = %{@schedule | language: "unsupported", enabled: enabled}
        changeset = Subscription.changeset(%Subscription{}, attrs, scope)

        assert_error(changeset, :language, :inclusion)
      end
    end

    test "accepts timezones with whole-hour, half-hour, and quarter-hour offsets", %{scope: scope} do
      for timezone <- ["Etc/UTC", "Europe/Rome", "Asia/Kolkata", "Asia/Kathmandu"] do
        attrs = %{@schedule | timezone: timezone}
        changeset = Subscription.changeset(%Subscription{}, attrs, scope)

        assert changeset.valid?
        assert Ecto.Changeset.get_field(changeset, :timezone) == timezone
      end
    end

    test "rejects an unknown timezone even when disabled", %{scope: scope} do
      for enabled <- [true, false] do
        attrs = %{@schedule | timezone: "Invalid/Timezone", enabled: enabled}
        changeset = Subscription.changeset(%Subscription{}, attrs, scope)

        refute changeset.valid?
        assert Keyword.has_key?(changeset.errors, :timezone)
      end
    end

    test "requires every calendar field when enabled", %{scope: scope} do
      for field <- [:weekdays, :local_hour, :timezone, :language] do
        attrs = Map.delete(@schedule, field)
        changeset = Subscription.changeset(%Subscription{}, attrs, scope)

        assert_error(changeset, field, :required)
      end
    end

    test "requires the calendar when enabling an existing subscription", %{scope: scope} do
      subscription = %Subscription{provider: "email", enabled: false, user_id: scope.user.id}
      changeset = Subscription.changeset(subscription, %{enabled: true}, scope)

      for field <- [:weekdays, :local_hour, :timezone, :language] do
        assert_error(changeset, field, :required)
      end
    end

    test "allows empty weekdays only when disabled", %{scope: scope} do
      enabled = Subscription.changeset(%Subscription{}, %{@schedule | weekdays: []}, scope)

      disabled =
        Subscription.changeset(
          %Subscription{},
          %{provider: "email", enabled: false, weekdays: []},
          scope
        )

      assert_error(enabled, :weekdays, :length)
      assert disabled.valid?
    end

    test "requires a name for Slack and Discord even when disabled", %{scope: scope} do
      for provider <- ["slack", "discord"] do
        for name <- [nil, "   "] do
          attrs = %{provider: provider, name: name, enabled: false}
          changeset = Subscription.changeset(%Subscription{}, attrs, scope)

          assert_error(changeset, :name, :required)
        end

        changeset =
          Subscription.changeset(
            %Subscription{},
            %{provider: provider, name: "Daily quotes", enabled: false},
            scope
          )

        assert changeset.valid?
      end
    end

    test "accepts all ISO weekdays and boundary hours", %{scope: scope} do
      for hour <- [0, 23] do
        attrs = %{@schedule | weekdays: Enum.to_list(1..7), local_hour: hour}
        changeset = Subscription.changeset(%Subscription{}, attrs, scope)

        assert changeset.valid?
      end
    end

    test "rejects invalid weekdays even when disabled", %{scope: scope} do
      for weekdays <- [[0], [8], [1, 8]] do
        attrs = %{provider: "email", weekdays: weekdays, enabled: false}
        changeset = Subscription.changeset(%Subscription{}, attrs, scope)

        assert_error(changeset, :weekdays, :subset)
      end
    end

    test "rejects invalid hours even when disabled", %{scope: scope} do
      for hour <- [-1, 24] do
        attrs = %{provider: "email", local_hour: hour, enabled: false}
        changeset = Subscription.changeset(%Subscription{}, attrs, scope)

        assert_error(changeset, :local_hour, :number)
      end
    end
  end

  describe "schedule_changeset/3" do
    test "ignores connection and ownership attributes", %{scope: scope} do
      subscription = %Subscription{
        provider: "email",
        user_id: scope.user.id,
        enabled: false
      }

      attrs = %{
        provider: "slack",
        name: "Another channel",
        user_id: 999,
        local_hour: 10
      }

      changeset = Subscription.schedule_changeset(subscription, attrs, scope)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :provider) == "email"
      assert Ecto.Changeset.get_field(changeset, :name) == nil
      assert Ecto.Changeset.get_field(changeset, :user_id) == scope.user.id
      assert Ecto.Changeset.get_field(changeset, :local_hour) == 10
    end

    test "validates enabled schedule values", %{scope: scope} do
      subscription = %Subscription{provider: "email", user_id: scope.user.id}
      attrs = %{@schedule | local_hour: 24, weekdays: [8]}
      changeset = Subscription.schedule_changeset(subscription, attrs, scope)

      assert_error(changeset, :local_hour, :number)
      assert_error(changeset, :weekdays, :subset)
    end

    test "requires a verified email for creation and schedule activation" do
      scope = Scope.for_user(%User{id: 1})
      subscription = %Subscription{provider: "email", user_id: scope.user.id}

      created = Subscription.changeset(%Subscription{}, @schedule, scope)
      updated = Subscription.schedule_changeset(subscription, @schedule, scope)

      assert_error(created, :enabled, :email_confirmation)
      assert_error(updated, :enabled, :email_confirmation)
    end

    test "allows an unverified user to disable email notifications" do
      scope = Scope.for_user(%User{id: 1})
      subscription = %Subscription{provider: "email", enabled: true, user_id: scope.user.id}
      changeset = Subscription.schedule_changeset(subscription, %{enabled: false}, scope)

      assert changeset.valid?
    end

    test "does not require account email verification for shared-channel schedules" do
      scope = Scope.for_user(%User{id: 1})

      for provider <- ["slack", "discord"] do
        subscription = %Subscription{
          provider: provider,
          name: "Daily quotes",
          user_id: scope.user.id
        }

        changeset = Subscription.schedule_changeset(subscription, @schedule, scope)
        assert changeset.valid?
      end
    end
  end

  defp assert_error(changeset, field, validation) do
    refute changeset.valid?
    {_message, options} = Keyword.fetch!(changeset.errors, field)
    assert options[:validation] == validation
  end
end
