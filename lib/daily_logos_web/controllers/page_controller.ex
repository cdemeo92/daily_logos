defmodule DailyLogosWeb.PageController do
  use DailyLogosWeb, :controller

  alias DailyLogosWeb.Plugs.{InvalidLocalePrefix, SeoMeta}

  plug InvalidLocalePrefix

  def home(conn, _params) do
    conn
    |> SeoMeta.put_page_meta(%{
      title: gettext("Daily Stoic Quote of the Day | Daily Logos"),
      description:
        gettext(
          "Read one Stoic quote every day, aligned with the calendar, and build a consistent reflection habit."
        )
    })
    |> render(:home)
  end

  def feedback(conn, _params) do
    conn
    |> SeoMeta.put_page_meta(%{
      title: gettext("Send Feedback | Daily Logos"),
      description:
        gettext(
          "Share feedback, ideas, bug reports, and suggestions to help improve Daily Logos."
        ),
      robots: "noindex,nofollow,noarchive"
    })
    |> render(:feedback)
  end

  def about(conn, _params) do
    conn
    |> SeoMeta.put_page_meta(%{
      title: gettext("About Daily Logos"),
      description:
        gettext(
          "Learn what Daily Logos is, why Stoicism matters, and how to get the most from one quote per day."
        )
    })
    |> render(:about)
  end

  def privacy(conn, _params) do
    conn
    |> SeoMeta.put_page_meta(%{
      title: gettext("Privacy & Cookie Policy | Daily Logos"),
      description:
        gettext(
          "Review how Daily Logos handles session, remember-me, consent, analytics, and embedded-content cookies."
        ),
      robots: "noindex,nofollow,noarchive"
    })
    |> render(:privacy)
  end

  def notifications(conn, _params) do
    login_path = ~p"/users/log-in" <> "?return_to=%2Fnotifications"
    register_path = ~p"/users/register" <> "?return_to=%2Fnotifications"

    conn
    |> SeoMeta.put_page_meta(%{
      title: gettext("Daily Stoic Quote Notifications | Daily Logos"),
      description:
        gettext(
          "Receive daily Stoic quotes through email, Slack, Telegram and more. Build a daily reflection habit with Daily Logos."
        ),
      robots: "index,follow"
    })
    |> assign(:notifications_login_path, login_path)
    |> assign(:notifications_register_path, register_path)
    |> render(:notifications)
  end

  def show(conn, %{"month" => month_str, "day" => day_str}) do
    with {month, ""} <- Integer.parse(month_str),
         {day, ""} <- Integer.parse(day_str),
         true <- month in 1..12 and day in 1..31,
         quote when not is_nil(quote) <- DailyLogos.Quotes.get_quote_by_day_month(day, month) do
      date = Date.new!(2000, month, 1) |> Date.add(day - 1)
      locale = Gettext.get_locale(DailyLogosWeb.Gettext)

      text = Map.get(quote, :"text_#{locale}") || quote.text_en || ""
      topic = Map.get(quote, :"topic_#{locale}") || quote.topic_en || ""

      conn
      |> SeoMeta.put_page_meta(%{
        title:
          gettext("\"%{topic}\" — %{author} | Daily Logos", topic: topic, author: quote.author),
        description: String.slice(text, 0, 160),
        keywords:
          gettext(
            "stoic quote %{author}, %{topic}, daily stoic, stoicism",
            author: quote.author,
            topic: topic
          )
      })
      |> assign(:extra_ld_nodes, [
        %{
          "@type" => "Quotation",
          "@id" => conn.assigns.seo_meta.canonical <> "#quotation",
          "text" => text,
          "spokenByCharacter" => %{"@type" => "Person", "name" => quote.author},
          "isPartOf" => %{"@id" => conn.assigns.seo_meta.canonical <> "#webpage"}
        }
      ])
      |> render(:show,
        month: month,
        day: day,
        date: date,
        quote_text: text,
        quote_topic: topic,
        quote_author: quote.author,
        quote_source: quote.source
      )
    else
      _ -> conn |> not_found(%{}) |> halt()
    end
  end

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> SeoMeta.put_page_meta(%{
      title: gettext("Page Not Found") <> " | Daily Logos",
      description: gettext("The page you requested does not exist."),
      robots: "noindex,nofollow,noarchive"
    })
    |> render(:not_found)
  end
end
