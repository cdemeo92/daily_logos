defmodule DailyLogosWeb.PageController do
  use DailyLogosWeb, :controller

  def home(conn, _params) do
    quote = %{
      text: "The virtue lies not in...",
      author: "Marcus Aurelius",
      source: "Meditations"
    }

    render(conn, :home, quote: quote)
  end
end
