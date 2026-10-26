defmodule DailyLogos.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false

  alias DailyLogos.Accounts.Scope
  alias DailyLogos.Notifications.Subscription
  alias DailyLogos.Repo

  @doc """
  Returns the list of notification_subscriptions.

  ## Examples

      iex> list_notification_subscriptions(scope)
      [%Subscription{}, ...]

  """
  def list_notification_subscriptions(%Scope{} = scope) do
    Subscription
    |> where(user_id: ^scope.user.id)
    |> order_by([subscription],
      asc: fragment("? <> 'email'", subscription.provider),
      asc: subscription.id
    )
    |> Repo.all()
  end

  @doc """
  Returns the user's saved email subscription, or nil without creating one.
  """
  def get_email_subscription(%Scope{} = scope) do
    Repo.get_by(Subscription, user_id: scope.user.id, provider: "email")
  end

  @doc """
  Gets a single subscription.

  Raises if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(scope, 123)
      %Subscription{}

  """
  def get_subscription!(%Scope{} = scope, id) do
    Subscription
    |> where(user_id: ^scope.user.id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(scope, %{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(scope, %{field: bad_value})
      {:error, ...}

  """
  def create_subscription(%Scope{} = scope, attrs) do
    %Subscription{}
    |> Subscription.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates only the calendar and enabled state of a subscription.
  Connection fields and ownership cannot be changed through this operation.

  ## Examples

      iex> update_subscription(scope, subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> update_subscription(scope, subscription, %{field: bad_value})
      {:error, ...}

  """
  def update_subscription(%Scope{} = scope, %Subscription{} = subscription, attrs) do
    true = subscription.user_id == scope.user.id

    subscription
    |> Subscription.schedule_changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a Subscription.

  ## Examples

      iex> delete_subscription(scope, subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(scope, subscription)
      {:error, ...}

  """
  def delete_subscription(%Scope{} = scope, %Subscription{} = subscription) do
    true = subscription.user_id == scope.user.id

    case subscription.provider do
      "email" -> {:error, :email_subscription_not_deletable}
      _provider -> Repo.delete(subscription)
    end
  end

  @doc """
  Returns a changeset for the subscription's calendar form without saving it.

  ## Examples

      iex> change_subscription(scope, subscription)
      %Ecto.Changeset{...}

  """
  def change_subscription(%Scope{} = scope, %Subscription{} = subscription, attrs \\ %{}) do
    true = subscription.user_id == scope.user.id

    Subscription.schedule_changeset(subscription, attrs, scope)
  end
end
