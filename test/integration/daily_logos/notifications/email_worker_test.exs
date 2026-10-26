defmodule DailyLogos.Notifications.EmailWorkerIntegrationTest do
  use DailyLogos.DataCase
  use Oban.Testing, repo: DailyLogos.Repo

  import DailyLogos.AccountsFixtures
  import DailyLogos.NotificationsFixtures
  import DailyLogos.QuotesFixtures
  import Swoosh.TestAssertions

  alias DailyLogos.Accounts.User
  alias DailyLogos.Notifications.EmailWorker

  test "sends the scheduled quote to the verified account email" do
    previous_url = Application.get_env(:daily_logos, :buy_me_coffee_url)

    Application.put_env(
      :daily_logos,
      :buy_me_coffee_url,
      "https://www.buymeacoffee.com/dailylogos"
    )

    on_exit(fn ->
      if previous_url do
        Application.put_env(:daily_logos, :buy_me_coffee_url, previous_url)
      else
        Application.delete_env(:daily_logos, :buy_me_coffee_url)
      end
    end)

    scope = user_scope_fixture()
    subscription = subscription_fixture(scope, %{language: "it"})
    quote = quote_fixture(%{day: 12, month: 1})

    assert_receive {:email, _authentication_email}

    assert :ok =
             perform_job(EmailWorker, %{
               "subscription_id" => subscription.id,
               "scheduled_for" => "2026-01-12T03:15:00Z",
               "local_date" => "2026-01-12",
               "quote_id" => quote.id,
               "language" => "it"
             })

    assert_email_sent(fn email ->
      assert email.to == [{"", scope.user.email}]
      assert email.subject == "La tua citazione stoica quotidiana"
      assert email.text_body =~ quote.text_it
      assert email.text_body =~ quote.author
      assert email.text_body =~ "2026-01-12"
      assert email.text_body =~ "Sostieni Daily Logos con un caffè."
      assert email.text_body =~ "https://www.buymeacoffee.com/dailylogos"
      assert email.html_body =~ "https://www.buymeacoffee.com/dailylogos"
      assert email.html_body =~ "Sostieni Daily Logos con un caffè."
      assert email.html_body =~ "https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png"
      assert email.html_body =~ "height=\"40\""
      assert email.html_body =~ "width=\"140\""
    end)
  end

  test "discards a queued email when the subscription is disabled" do
    scope = user_scope_fixture()
    subscription = subscription_fixture(scope, %{enabled: false})
    quote = quote_fixture()

    assert_receive {:email, _authentication_email}

    assert {:discard, :subscription_inactive} =
             perform_job(EmailWorker, %{
               "subscription_id" => subscription.id,
               "scheduled_for" => "2026-01-12T03:15:00Z",
               "local_date" => "2026-01-12",
               "quote_id" => quote.id,
               "language" => subscription.language
             })

    refute_receive {:email, _email}
  end

  test "discards a queued email when the account email is no longer verified" do
    scope = user_scope_fixture()
    subscription = subscription_fixture(scope)
    quote = quote_fixture()

    assert_receive {:email, _authentication_email}

    Repo.update_all(from(user in User, where: user.id == ^scope.user.id),
      set: [confirmed_at: nil]
    )

    assert {:discard, :subscription_inactive} =
             perform_job(EmailWorker, %{
               "subscription_id" => subscription.id,
               "scheduled_for" => "2026-01-12T03:15:00Z",
               "local_date" => "2026-01-12",
               "quote_id" => quote.id,
               "language" => subscription.language
             })

    refute_receive {:email, _email}
  end
end
