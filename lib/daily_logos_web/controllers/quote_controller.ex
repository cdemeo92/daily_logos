defmodule DailyLogosWeb.QuoteController do
  use DailyLogosWeb, :controller

  alias DailyLogos.Quotes

  action_fallback DailyLogosWeb.FallbackController

  def show(conn, %{"day" => day, "month" => month}) do
    quote = Quotes.get_quote_by_day_month(String.to_integer(day), String.to_integer(month))
    render(conn, :show, quote: quote)
  end
end
