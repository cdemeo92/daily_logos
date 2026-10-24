defmodule DailyLogos.Notifications.SubscriptionIntegrationTest do
  use DailyLogos.DataCase

  import DailyLogos.AccountsFixtures

  alias DailyLogos.Notifications.Subscription

  describe "email subscription uniqueness" do
    test "returns a changeset error for a second email subscription belonging to the same user" do
      scope = user_scope_fixture()
      attrs = %{provider: "email", enabled: false}

      assert {:ok, original} = insert_subscription(scope, attrs)
      assert {:error, changeset} = insert_subscription(scope, attrs)

      {_message, options} = Keyword.fetch!(changeset.errors, :user_id)
      assert options[:constraint] == :unique
      assert options[:constraint_name] == "notification_subscriptions_one_email_per_user"
      assert Repo.aggregate(Subscription, :count) == 1
      assert Repo.get!(Subscription, original.id).user_id == scope.user.id
    end

    test "allows an email subscription for each user" do
      first_scope = user_scope_fixture()
      second_scope = user_scope_fixture()
      attrs = %{provider: "email", enabled: false}

      assert {:ok, first} = insert_subscription(first_scope, attrs)
      assert {:ok, second} = insert_subscription(second_scope, attrs)

      assert first.user_id == first_scope.user.id
      assert second.user_id == second_scope.user.id
      assert first.id != second.id
      assert Repo.aggregate(Subscription, :count) == 2
    end

    test "allows multiple Slack subscriptions alongside the user's email subscription" do
      scope = user_scope_fixture()

      assert {:ok, _email} = insert_subscription(scope, %{provider: "email", enabled: false})

      assert {:ok, first} =
               insert_subscription(scope, %{
                 provider: "slack",
                 name: "Team Design",
                 enabled: false
               })

      assert {:ok, second} =
               insert_subscription(scope, %{
                 provider: "slack",
                 name: "Team Engineering",
                 enabled: false
               })

      assert first.user_id == scope.user.id
      assert second.user_id == scope.user.id
      assert first.id != second.id
      assert Repo.aggregate(Subscription, :count) == 3
    end
  end

  defp insert_subscription(scope, attrs) do
    %Subscription{}
    |> Subscription.changeset(attrs, scope)
    |> Repo.insert()
  end
end
