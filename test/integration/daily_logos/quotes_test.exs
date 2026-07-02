defmodule DailyLogos.QuotesTest do
  use DailyLogos.DataCase

  alias DailyLogos.Quotes
  import DailyLogos.QuotesFixtures

  describe "quotes" do
    alias DailyLogos.Quotes.Quote

    @invalid_attrs %{
      author: nil,
      month: nil,
      source: nil,
      day: nil,
      topic_en: nil,
      topic_it: nil,
      text_en: nil,
      text_it: nil
    }

    test "list_quotes/0 returns all quotes" do
      quote = quote_fixture()
      assert Quotes.list_quotes() == [quote]
    end

    test "get_quote!/1 returns the quote with given id" do
      quote = quote_fixture()
      assert Quotes.get_quote!(quote.id) == quote
    end

    test "create_quote/1 with valid data creates a quote" do
      valid_attrs = %{
        author: "some author",
        month: 42,
        source: "some source",
        day: 42,
        topic_en: "some topic_en",
        topic_it: "some topic_it",
        text_en: "some text_en",
        text_it: "some text_it"
      }

      assert {:ok, %Quote{} = quote} = Quotes.create_quote(valid_attrs)
      assert quote.author == "some author"
      assert quote.month == 42
      assert quote.source == "some source"
      assert quote.day == 42
      assert quote.topic_en == "some topic_en"
      assert quote.topic_it == "some topic_it"
      assert quote.text_en == "some text_en"
      assert quote.text_it == "some text_it"
    end

    test "create_quote/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Quotes.create_quote(@invalid_attrs)
    end

    test "update_quote/2 with valid data updates the quote" do
      quote = quote_fixture()

      update_attrs = %{
        author: "some updated author",
        month: 43,
        source: "some updated source",
        day: 43,
        topic_en: "some updated topic_en",
        topic_it: "some updated topic_it",
        text_en: "some updated text_en",
        text_it: "some updated text_it"
      }

      assert {:ok, %Quote{} = quote} = Quotes.update_quote(quote, update_attrs)
      assert quote.author == "some updated author"
      assert quote.month == 43
      assert quote.source == "some updated source"
      assert quote.day == 43
      assert quote.topic_en == "some updated topic_en"
      assert quote.topic_it == "some updated topic_it"
      assert quote.text_en == "some updated text_en"
      assert quote.text_it == "some updated text_it"
    end

    test "update_quote/2 with invalid data returns error changeset" do
      quote = quote_fixture()
      assert {:error, %Ecto.Changeset{}} = Quotes.update_quote(quote, @invalid_attrs)
      assert quote == Quotes.get_quote!(quote.id)
    end

    test "delete_quote/1 deletes the quote" do
      quote = quote_fixture()
      assert {:ok, %Quote{}} = Quotes.delete_quote(quote)
      assert_raise Ecto.NoResultsError, fn -> Quotes.get_quote!(quote.id) end
    end

    test "change_quote/1 returns a quote changeset" do
      quote = quote_fixture()
      assert %Ecto.Changeset{} = Quotes.change_quote(quote)
    end
  end

  describe "get_quote_by_day_month/2" do
    test "returns a quote when found" do
      quote = quote_fixture(day: 15, month: 6)
      assert Quotes.get_quote_by_day_month(15, 6) == quote
    end

    test "returns nil when quote not found" do
      assert Quotes.get_quote_by_day_month(31, 2) == nil
    end

    test "distinguishes quotes by day and month" do
      quote1 = quote_fixture(day: 15, month: 6)
      quote2 = quote_fixture(day: 15, month: 7)

      assert Quotes.get_quote_by_day_month(15, 6) == quote1
      assert Quotes.get_quote_by_day_month(15, 7) == quote2
    end
  end
end
