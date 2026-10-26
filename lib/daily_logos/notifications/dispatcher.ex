defmodule DailyLogos.Notifications.Dispatcher do
  @moduledoc "Dispatches due email notifications for each UTC quarter-hour slot."

  use Oban.Worker, queue: :notifications_email

  import Ecto.Query

  alias DailyLogos.Notifications.EmailWorker
  alias DailyLogos.Notifications.Subscription
  alias DailyLogos.Quotes
  alias DailyLogos.Repo

  @batch_size 500

  @impl Oban.Worker
  def perform(%Oban.Job{scheduled_at: scheduled_at}) do
    dispatch_batch(0, utc_quarter_hour_slot(scheduled_at))
  end

  defp utc_quarter_hour_slot(scheduled_at) do
    minute = div(scheduled_at.minute, 15) * 15
    %{scheduled_at | minute: minute, second: 0, microsecond: {0, 0}}
  end

  defp dispatch_batch(last_id, utc_slot) do
    Subscription
    |> where(
      [subscription],
      subscription.provider == "email" and subscription.enabled and subscription.id > ^last_id
    )
    |> order_by([subscription], asc: subscription.id)
    |> limit(@batch_size)
    |> Repo.all()
    |> case do
      [] ->
        :ok

      subscriptions ->
        case enqueue_subscriptions(subscriptions, utc_slot) do
          :ok -> dispatch_batch(List.last(subscriptions).id, utc_slot)
          error -> error
        end
    end
  end

  defp enqueue_subscriptions(subscriptions, utc_slot) do
    Enum.reduce_while(subscriptions, :ok, fn subscription, :ok ->
      case job_for_subscription(subscription, utc_slot) do
        nil ->
          {:cont, :ok}

        changeset ->
          insert_job(changeset)
      end
    end)
  end

  defp insert_job(changeset) do
    case Oban.insert(changeset) do
      {:ok, _job} -> {:cont, :ok}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp job_for_subscription(subscription, utc_slot) do
    with {:ok, local_slot} <- DateTime.shift_zone(utc_slot, subscription.timezone),
         true <- due?(subscription, local_slot),
         %{} = quote <- Quotes.get_quote_by_day_month(local_slot.day, local_slot.month) do
      args = %{
        subscription_id: subscription.id,
        scheduled_for: utc_slot |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
        local_date: local_slot |> DateTime.to_date() |> Date.to_iso8601(),
        quote_id: quote.id,
        language: subscription.language
      }

      Oban.Job.new(args,
        worker: EmailWorker,
        queue: :notifications_email,
        unique: [
          fields: [:args, :worker],
          keys: [:subscription_id, :scheduled_for],
          period: :infinity,
          states: :all
        ]
      )
    else
      _ -> nil
    end
  end

  defp due?(subscription, local_slot) do
    local_slot.minute == 0 and local_slot.second == 0 and
      local_slot.hour == subscription.local_hour and
      Date.day_of_week(DateTime.to_date(local_slot)) in subscription.weekdays
  end
end
