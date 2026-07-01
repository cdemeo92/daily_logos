defmodule DailyLogosWeb.QuoteJSON do
  alias DailyLogos.Quotes.Quote

  @doc """
  Renders a list of quotes.
  """
  def index(%{quotes: quotes}) do
    %{data: for(quote <- quotes, do: data(quote))}
  end

  @doc """
  Renders a single quote.
  """
  def show(%{quote: quote}) do
    %{data: data(quote)}
  end

  defp data(%Quote{} = quote) do
    %{
      id: quote.id,
      day: quote.day,
      month: quote.month,
      author: quote.author,
      source: quote.source,
      topic: quote.topic,
      text_en: quote.text_en,
      text_it: quote.text_it
    }
  end
end
