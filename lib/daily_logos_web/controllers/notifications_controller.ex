defmodule DailyLogosWeb.NotificationsController do
  use DailyLogosWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyLogos.Notifications
  alias DailyLogos.Notifications.Subscription
  alias OpenApiSpex.Schema

  tags(["Notifications"])
  security([%{"sessionCookie" => [], "csrfToken" => []}])

  operation(:create,
    operation_id: "createEmailNotificationSubscription",
    summary: "Create the authenticated user's email notification subscription",
    request_body:
      {"Notification schedule", "application/json",
       DailyLogosWeb.Schemas.NotificationScheduleRequest, required: true},
    responses: [
      created:
        {"Subscription created", "application/json",
         DailyLogosWeb.Schemas.NotificationSubscriptionResponse},
      unauthorized:
        {"Authentication required", "application/json",
         DailyLogosWeb.Schemas.NotificationApiErrorResponse},
      unprocessable_entity:
        {"Schedule validation failed", "application/json",
         DailyLogosWeb.Schemas.NotificationApiErrorResponse}
    ]
  )

  operation(:update,
    operation_id: "updateEmailNotificationSubscription",
    summary: "Update the authenticated user's email notification schedule",
    parameters: [
      id: [
        in: :path,
        description: "Subscription ID",
        schema: %Schema{type: :integer},
        required: true
      ]
    ],
    request_body:
      {"Notification schedule", "application/json",
       DailyLogosWeb.Schemas.NotificationScheduleRequest, required: true},
    responses: [
      ok:
        {"Subscription updated", "application/json",
         DailyLogosWeb.Schemas.NotificationSubscriptionResponse},
      unauthorized:
        {"Authentication required", "application/json",
         DailyLogosWeb.Schemas.NotificationApiErrorResponse},
      not_found:
        {"Subscription not found", "application/json",
         DailyLogosWeb.Schemas.NotificationApiErrorResponse},
      unprocessable_entity:
        {"Schedule validation failed", "application/json",
         DailyLogosWeb.Schemas.NotificationApiErrorResponse}
    ]
  )

  def create(conn, %{"subscription" => attrs}) do
    attrs =
      attrs
      |> schedule_attrs()
      |> Map.take(["weekdays", "local_hour", "timezone", "language", "enabled"])
      |> Map.put("provider", "email")

    conn.assigns.current_scope
    |> Notifications.create_subscription(attrs)
    |> respond(conn, :created)
  end

  def update(conn, %{"id" => id, "subscription" => attrs}) do
    scope = conn.assigns.current_scope
    subscription = Notifications.get_subscription!(scope, id)

    scope
    |> Notifications.update_subscription(subscription, schedule_attrs(attrs))
    |> respond(conn, :ok)
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: %{code: "not_found"}})
  end

  defp schedule_attrs(attrs) do
    Map.update(attrs, "weekdays", [], fn
      weekdays when is_list(weekdays) -> Enum.reject(weekdays, &(&1 in ["", nil]))
      weekdays -> weekdays
    end)
  end

  defp respond({:ok, %Subscription{} = subscription}, conn, status) do
    conn
    |> put_status(status)
    |> json(%{
      data: %{
        id: subscription.id,
        provider: subscription.provider,
        weekdays: subscription.weekdays,
        local_hour: subscription.local_hour,
        timezone: subscription.timezone,
        language: subscription.language,
        enabled: subscription.enabled
      },
      message: "Notification settings saved."
    })
  end

  defp respond({:error, %Ecto.Changeset{} = changeset}, conn, _status) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, &translate_error_in_english/1)

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: %{
        code: "validation_failed",
        message: "Could not save changes. Please check the fields below.",
        fields: errors
      }
    })
  end

  defp translate_error_in_english(error) do
    Gettext.with_locale(DailyLogosWeb.Gettext, "en", fn ->
      DailyLogosWeb.CoreComponents.translate_error(error)
    end)
  end
end
