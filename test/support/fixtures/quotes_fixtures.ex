defmodule DailyLogos.QuotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DailyLogos.Quotes` context.
  """

  @doc """
  Generate a quote.
  """
  def quote_fixture(attrs \\ %{}) do
    {:ok, quote} =
      attrs
      |> Enum.into(%{
        author: "some author",
        day: 1,
        month: 1,
        source: "some source",
        text_en: "some text_en",
        text_it: "some text_it",
        topic_en: "some topic_en",
        topic_it: "some topic_it"
      })
      |> DailyLogos.Quotes.create_quote()

    quote
  end
end
