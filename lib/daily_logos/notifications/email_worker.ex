defmodule DailyLogos.Notifications.EmailWorker do
  @moduledoc "Delivers scheduled quote notifications through the configured mailer."

  use Oban.Worker, queue: :notifications_email
  use Gettext, backend: DailyLogosWeb.Gettext

  import Ecto.Query

  alias DailyLogos.Accounts.User
  alias DailyLogos.EmailTemplate
  alias DailyLogos.Mailer
  alias DailyLogos.Notifications.Subscription
  alias DailyLogos.Quotes
  alias DailyLogos.Quotes.Quote
  alias DailyLogos.Repo
  alias Swoosh.Email

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    with {:ok, subscription_id} <- positive_integer(args["subscription_id"]),
         {:ok, quote_id} <- positive_integer(args["quote_id"]),
         {:ok, local_date} <- Date.from_iso8601(args["local_date"]),
         true <- valid_scheduled_for?(args["scheduled_for"]),
         language when is_binary(language) <- args["language"],
         true <- language in Gettext.known_locales(DailyLogosWeb.Gettext),
         {%Subscription{} = _subscription, %User{} = user} <-
           eligible_subscription(subscription_id),
         %Quote{} = quote <- Quotes.get_quote!(quote_id),
         {:ok, email} <- build_email(user.email, quote, language, local_date) do
      case Mailer.deliver(email) do
        {:ok, _metadata} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      nil -> {:discard, :subscription_inactive}
      false -> {:discard, :invalid_notification}
      {:error, :invalid_id} -> {:discard, :invalid_notification}
      {:error, :invalid_quote} -> {:discard, :invalid_notification}
      _ -> {:discard, :invalid_notification}
    end
  end

  defp eligible_subscription(subscription_id) do
    query =
      from subscription in Subscription,
        join: user in User,
        on: user.id == subscription.user_id,
        where:
          subscription.id == ^subscription_id and subscription.provider == "email" and
            subscription.enabled and not is_nil(user.confirmed_at),
        select: {subscription, user}

    Repo.one(query)
  end

  defp build_email(recipient, quote, language, local_date) do
    with {:ok, text} <- quote_translation(quote, :text, language),
         {:ok, topic} <- quote_translation(quote, :topic, language) do
      translations =
        Gettext.with_locale(DailyLogosWeb.Gettext, language, fn ->
          %{
            subject: gettext("Your daily Stoic quote"),
            introduction:
              gettext("A Stoic reflection for %{date}.", date: Date.to_iso8601(local_date)),
            author: gettext("By %{author}", author: quote.author),
            source: gettext("Source: %{source}", source: quote.source),
            theme: gettext("Theme: %{topic}", topic: topic),
            manage_notifications: gettext("Manage your notification settings"),
            delete_account: gettext("Delete your account"),
            support_prompt: gettext("Enjoying your daily reflection?"),
            support_copy: gettext("Support Daily Logos with a coffee.")
          }
        end)

      buy_me_coffee_url = buy_me_coffee_url()
      manage_notifications_url = localized_endpoint_url("/notifications", language)
      delete_account_url = localized_endpoint_url("/users/account/privacy", language)

      body_sections = [
        translations.introduction,
        text,
        translations.author,
        translations.source,
        translations.theme
      ]

      body_sections =
        if buy_me_coffee_url do
          body_sections ++
            [translations.support_prompt, translations.support_copy, buy_me_coffee_url]
        else
          body_sections
        end

      body_sections =
        body_sections ++
          [
            translations.manage_notifications,
            manage_notifications_url,
            translations.delete_account,
            delete_account_url
          ]

      body = Enum.join(body_sections, "\n\n")

      html_body =
        render_email_html(
          language,
          translations,
          text,
          buy_me_coffee_url,
          manage_notifications_url,
          delete_account_url
        )

      email =
        Email.new()
        |> Email.to(recipient)
        |> Email.from({"Daily Logos", Application.fetch_env!(:daily_logos, :mailer_from)})
        |> Email.subject(translations.subject)
        |> Email.text_body(body)
        |> Email.html_body(html_body)

      {:ok, email}
    end
  end

  defp render_email_html(
         language,
         translations,
         text,
         buy_me_coffee_url,
         manage_notifications_url,
         delete_account_url
       ) do
    quote_text = text |> EmailTemplate.escape_html() |> String.replace(~r/\r\n?|\n/, "<br>\n")

    support_section =
      if buy_me_coffee_url do
        """
        <tr>
          <td style="padding:24px 32px 28px;border-top:1px solid #e8e4dc;text-align:center;">
            <p style="margin:0 0 8px;color:#252525;font-size:16px;font-weight:700;">
              #{EmailTemplate.escape_html(translations.support_prompt)}
            </p>
            <p style="margin:0 0 16px;color:#62605a;font-size:14px;line-height:1.5;">
              #{EmailTemplate.escape_html(translations.support_copy)}
            </p>
            <a href="#{EmailTemplate.escape_html(buy_me_coffee_url)}" target="_blank" rel="noopener noreferrer">
              <img
                src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png"
                alt="Buy Me a Coffee"
                width="140"
                height="40"
                style="display:inline-block;height:40px;width:140px;border:0;"
              />
            </a>
          </td>
        </tr>
        """
      else
        ""
      end

    content_html = """
    <p style="margin:0 0 20px;color:#55534e;font-size:15px;line-height:1.6;">
      #{EmailTemplate.escape_html(translations.introduction)}
    </p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;background-color:#f8f7f4;border-left:4px solid #e7a83e;">
      <tr>
        <td style="padding:22px 24px;">
          <p style="margin:0;color:#252525;font-family:Georgia,'Times New Roman',serif;font-size:21px;line-height:1.55;">
            #{quote_text}
          </p>
        </td>
      </tr>
    </table>
    <p style="margin:18px 0 0;color:#252525;font-size:14px;font-weight:700;">
      #{EmailTemplate.escape_html(translations.author)}
    </p>
    <p style="margin:6px 0 0;color:#77736b;font-size:13px;line-height:1.5;">
      #{EmailTemplate.escape_html(translations.source)}
    </p>
    <p style="margin:4px 0 0;color:#77736b;font-size:13px;line-height:1.5;">
      #{EmailTemplate.escape_html(translations.theme)}
    </p>
    """

    footer_links = """
    <tr>
      <td style="padding:8px 32px 16px;text-align:center;">
    <p style="margin:0 0 10px;font-size:13px;line-height:1.5;text-align:center;">
      <a href="#{EmailTemplate.escape_html(manage_notifications_url)}" style="color:#252525;text-decoration:underline;">
        #{EmailTemplate.escape_html(translations.manage_notifications)}
      </a>
    </p>
    <p style="margin:0;font-size:13px;line-height:1.5;text-align:center;">
      <a href="#{EmailTemplate.escape_html(delete_account_url)}" style="color:#252525;text-decoration:underline;">
        #{EmailTemplate.escape_html(translations.delete_account)}
      </a>
    </p>
      </td>
    </tr>
    """

    EmailTemplate.render(
      language,
      translations.subject,
      content_html,
      support_section <> footer_links
    )
  end

  defp localized_endpoint_url(path, language) do
    endpoint_config = Application.fetch_env!(:daily_logos, DailyLogosWeb.Endpoint)
    url_config = Keyword.fetch!(endpoint_config, :url)

    scheme =
      Keyword.get(
        url_config,
        :scheme,
        if(Keyword.has_key?(endpoint_config, :https), do: "https", else: "http")
      )

    transport = if scheme == "https", do: :https, else: :http

    port =
      Keyword.get(url_config, :port) ||
        endpoint_config
        |> Keyword.get(transport, [])
        |> Keyword.get(:port, URI.default_port(scheme))

    path = DailyLogosWeb.LocalePaths.localized_path(path, language)

    URI.to_string(%URI{
      scheme: to_string(scheme),
      host: Keyword.fetch!(url_config, :host),
      port: port,
      path: path
    })
  end

  defp buy_me_coffee_url do
    case Application.get_env(:daily_logos, :buy_me_coffee_url) do
      url when is_binary(url) and url != "" -> url
      _ -> nil
    end
  end

  defp quote_translation(quote, field_prefix, language) do
    default_locale =
      Application.fetch_env!(:daily_logos, :i18n) |> Keyword.fetch!(:default_locale)

    value =
      translation_field(quote, field_prefix, language) ||
        translation_field(quote, field_prefix, default_locale)

    if is_binary(value), do: {:ok, value}, else: {:error, :invalid_quote}
  end

  defp translation_field(quote, field_prefix, language) do
    field_name = "#{field_prefix}_#{language}"

    case Enum.find(Quote.__schema__(:fields), &(Atom.to_string(&1) == field_name)) do
      nil -> nil
      field -> Map.get(quote, field)
    end
  end

  defp positive_integer(value) when is_integer(value) and value > 0, do: {:ok, value}
  defp positive_integer(_value), do: {:error, :invalid_id}

  defp valid_scheduled_for?(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, _datetime, _offset} -> true
      _ -> false
    end
  end

  defp valid_scheduled_for?(_value), do: false
end
