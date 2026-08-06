defmodule DailyLogosWeb.PageController do
  use DailyLogosWeb, :controller

  alias DailyLogosWeb.Plugs.SeoMeta

  plug :guard_invalid_locale_prefix

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

  def support(conn, _params) do
    conn
    |> SeoMeta.put_page_meta(%{
      title: gettext("Support Daily Logos"),
      description:
        gettext("Support Daily Logos and help keep Stoic wisdom freely accessible every day."),
      robots: "noindex,follow"
    })
    |> render(:support)
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
          "Read how Daily Logos handles personal data, technical cookies, analytics cookies, and consent preferences."
        ),
      robots: "noindex,nofollow,noarchive"
    })
    |> render(:privacy)
  end

  def show(conn, %{"month" => month_str, "day" => day_str}) do
    with {month, ""} <- Integer.parse(month_str),
         {day, ""} <- Integer.parse(day_str),
         true <- month in 1..12 and day in 1..31,
         quote when not is_nil(quote) <- DailyLogos.Quotes.get_quote_by_day_month(day, month) do
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

  defp guard_invalid_locale_prefix(
         %Plug.Conn{assigns: %{invalid_locale_prefix: true}} = conn,
         _opts
       ) do
    conn
    |> not_found(%{})
    |> halt()
  end

  defp guard_invalid_locale_prefix(conn, _opts), do: conn
end
