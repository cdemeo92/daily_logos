defmodule DailyLogos.Notifications.DispatcherIntegrationTest do
  use DailyLogos.DataCase
  use Oban.Testing, repo: DailyLogos.Repo

  import DailyLogos.AccountsFixtures
  import DailyLogos.NotificationsFixtures
  import DailyLogos.QuotesFixtures

  alias DailyLogos.Notifications.Dispatcher
  alias DailyLogos.Notifications.EmailWorker

  test "enqueues email only for enabled subscriptions due at the UTC quarter-hour slot" do
    scope = user_scope_fixture()
    quote = quote_fixture(%{day: 12, month: 1})

    due_subscription =
      subscription_fixture(scope, %{
        enabled: true,
        weekdays: [1],
        local_hour: 9,
        timezone: "Asia/Kathmandu",
        language: "it"
      })

    not_due_scope = user_scope_fixture()

    _not_due_subscription =
      subscription_fixture(not_due_scope, %{
        enabled: true,
        weekdays: [1],
        local_hour: 9,
        timezone: "Etc/UTC",
        language: "en"
      })

    disabled_scope = user_scope_fixture()

    _disabled_subscription =
      subscription_fixture(disabled_scope, %{
        enabled: false,
        weekdays: [1],
        local_hour: 9,
        timezone: "Asia/Kathmandu",
        language: "en"
      })

    utc_slot = ~U[2026-01-12 03:15:00Z]
    cron_scheduled_at = ~U[2026-01-12 03:15:37Z]

    assert :ok = Oban.Testing.perform_job(Dispatcher, %{}, scheduled_at: cron_scheduled_at)
    assert :ok = Oban.Testing.perform_job(Dispatcher, %{}, scheduled_at: cron_scheduled_at)

    assert [%Oban.Job{args: args}] =
             all_enqueued(queue: :notifications_email, worker: EmailWorker)

    assert args == %{
             "subscription_id" => due_subscription.id,
             "scheduled_for" => DateTime.to_iso8601(utc_slot),
             "local_date" => "2026-01-12",
             "quote_id" => quote.id,
             "language" => "it"
           }
  end
end
