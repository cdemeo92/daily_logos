defmodule DailyLogos.Accounts.UserNotifier do
  @moduledoc """
  Builds and delivers email notifications for account actions.
  """

  import Swoosh.Email
  use Gettext, backend: DailyLogosWeb.Gettext

  alias DailyLogos.Accounts.User
  alias DailyLogos.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"DailyLogos", Application.fetch_env!(:daily_logos, :mailer_from)})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    body =
      gettext(
        """

        ==============================

        Hi %{email},

        You can change your email by visiting the URL below:

        %{url}

        If you didn't request this change, please ignore this.

        ==============================
        """,
        email: user.email,
        url: url
      )

    deliver(user.email, gettext("Update email instructions"), body)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    body =
      gettext(
        """

        ==============================

        Hi %{email},

        You can log into your account by visiting the URL below:

        %{url}

        If you didn't request this email, please ignore this.

        ==============================
        """,
        email: user.email,
        url: url
      )

    deliver(user.email, gettext("Log in instructions"), body)
  end

  defp deliver_confirmation_instructions(user, url) do
    body =
      gettext(
        """

        ==============================

        Hi %{email},

        You can confirm your account by visiting the URL below:

        %{url}

        If you didn't create an account with us, please ignore this.

        ==============================
        """,
        email: user.email,
        url: url
      )

    deliver(user.email, gettext("Confirmation instructions"), body)
  end
end
