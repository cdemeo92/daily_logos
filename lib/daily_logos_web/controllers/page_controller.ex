defmodule DailyLogosWeb.PageController do
  use DailyLogosWeb, :controller

  alias DailyLogosWeb.Plugs.SeoMeta

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
        )
    })
    |> render(:feedback)
  end

  def support(conn, _params) do
    conn
    |> SeoMeta.put_page_meta(%{
      title: gettext("Support Daily Logos"),
      description:
        gettext("Support Daily Logos and help keep Stoic wisdom freely accessible every day.")
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
        )
    })
    |> render(:privacy)
  end

  def not_found(conn, _params) do
    redirect(conn, to: "/")
  end
end
