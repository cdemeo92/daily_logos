defmodule DailyLogos.Notifications.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notification_subscriptions" do
    field :provider, :string
    field :name, :string
    field :weekdays, {:array, :integer}
    field :local_hour, :integer
    field :timezone, :string
    field :language, :string
    field :enabled, :boolean, default: false
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscription, attrs, user_scope) do
    subscription
    |> cast(attrs, [:provider, :name, :weekdays, :local_hour, :timezone, :language, :enabled])
    |> validate_settings(user_scope)
    |> put_change(:user_id, user_scope.user.id)
    |> unique_constraint(:user_id,
      name: :notification_subscriptions_one_email_per_user,
      message: "already has an email subscription"
    )
  end

  @doc false
  def schedule_changeset(subscription, attrs, user_scope) do
    subscription
    |> cast(attrs, [:weekdays, :local_hour, :timezone, :language, :enabled])
    |> validate_settings(user_scope)
  end

  defp validate_settings(changeset, user_scope) do
    changeset
    |> validate_required([:provider, :enabled])
    |> validate_inclusion(:provider, ["email", "slack", "discord"])
    |> validate_inclusion(:language, Gettext.known_locales(DailyLogosWeb.Gettext))
    |> validate_subset(:weekdays, 1..7)
    |> validate_number(:local_hour,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 23
    )
    |> validate_enabled_schedule()
    |> validate_destination_name()
    |> validate_timezone()
    |> validate_email_confirmation(user_scope)
  end

  defp validate_email_confirmation(changeset, user_scope) do
    if get_field(changeset, :provider) == "email" and
         get_field(changeset, :enabled) == true and is_nil(user_scope.user.confirmed_at) do
      add_error(changeset, :enabled, "verify your email to enable notifications",
        validation: :email_confirmation
      )
    else
      changeset
    end
  end

  defp validate_enabled_schedule(changeset) do
    if get_field(changeset, :enabled) do
      validate_required(changeset, [
        :weekdays,
        :local_hour,
        :timezone,
        :language
      ])
      |> validate_length(:weekdays, min: 1)
    else
      changeset
    end
  end

  defp validate_destination_name(changeset) do
    if get_field(changeset, :provider) in ["slack", "discord"] do
      validate_required(changeset, [:name])
    else
      changeset
    end
  end

  defp validate_timezone(changeset) do
    validate_change(changeset, :timezone, fn :timezone, tz ->
      if Tzdata.zone_exists?(tz) do
        []
      else
        [timezone: "is not a valid timezone"]
      end
    end)
  end
end
