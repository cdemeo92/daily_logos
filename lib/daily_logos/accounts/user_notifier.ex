defmodule DailyLogos.Accounts.UserNotifier do
  @moduledoc """
  Builds and delivers email notifications for account actions.
  """

  import Swoosh.Email
  use Gettext, backend: DailyLogosWeb.Gettext

  alias DailyLogos.Accounts.User
  alias DailyLogos.EmailTemplate
  alias DailyLogos.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body, action_url, action_label) do
    language = Gettext.get_locale(DailyLogosWeb.Gettext)

    html_body =
      body
      |> account_content_html(action_url, action_label)
      |> then(&EmailTemplate.render(language, subject, &1))

    email =
      new()
      |> to(recipient)
      |> from({"DailyLogos", Application.fetch_env!(:daily_logos, :mailer_from)})
      |> subject(subject)
      |> text_body(body)
      |> html_body(html_body)

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

    deliver(
      user.email,
      gettext("Update email instructions"),
      body,
      url,
      gettext("Confirm email change")
    )
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

    deliver(
      user.email,
      gettext("Log in instructions"),
      body,
      url,
      gettext("Log in to your account")
    )
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

    deliver(
      user.email,
      gettext("Confirmation instructions"),
      body,
      url,
      gettext("Confirm your account")
    )
  end

  defp account_content_html(body, action_url, action_label) do
    body
    |> String.trim()
    |> String.split("\n\n", trim: true)
    |> Enum.reject(&(&1 == "==============================" or &1 == action_url))
    |> Enum.map_join(fn paragraph ->
      """
      <p style="margin:0 0 16px;color:#55534e;font-size:15px;line-height:1.6;">
        #{EmailTemplate.escape_html(paragraph)}
      </p>
      """
    end)
    |> Kernel.<>(action_button_html(action_url, action_label))
  end

  defp action_button_html(action_url, action_label) do
    """
    <p style="margin:24px 0;text-align:center;">
      <a href="#{EmailTemplate.escape_html(action_url)}" style="display:inline-block;padding:13px 20px;border-radius:4px;background-color:#f4b942;color:#252525;font-size:14px;font-weight:700;text-decoration:none;">
        #{EmailTemplate.escape_html(action_label)}
      </a>
    </p>
    """
  end
end
