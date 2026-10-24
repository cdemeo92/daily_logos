defmodule DailyLogos.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DailyLogos.Notifications` context.
  """

  @doc """
  Generate a subscription.
  """
  def subscription_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        enabled: true,
        language: Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale),
        local_hour: 9,
        provider: "email",
        timezone: "Etc/UTC",
        weekdays: [1, 2]
      })

    {:ok, subscription} = DailyLogos.Notifications.create_subscription(scope, attrs)
    subscription
  end
end
