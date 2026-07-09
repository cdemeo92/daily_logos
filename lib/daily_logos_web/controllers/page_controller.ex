defmodule DailyLogosWeb.PageController do
  use DailyLogosWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def feedback(conn, _params) do
    feedback_form_url =
      case Application.get_env(:daily_logos, :feedback_form_url) do
        url when is_binary(url) and url != "" -> url
        _ -> nil
      end

    render(conn, :feedback, feedback_form_url: feedback_form_url)
  end
end
