# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DailyLogos.Repo.insert!(%DailyLogos.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias DailyLogos.Quotes.Quote
alias DailyLogos.Repo

csv_path = Path.join(__DIR__, "seeds/quotes.csv")

csv_field_regex = ~r/(?:^|,)(?:"((?:[^"]|"")*)"|([^",]*))/u

parse_csv_line = fn line ->
  csv_field_regex
  |> Regex.scan(line, capture: :all_but_first)
  |> Enum.map(fn
    [value] ->
      String.replace(value, ~s(""), ~s("))

    [quoted, unquoted] ->
      value = if quoted != "", do: quoted, else: unquoted
      String.replace(value, ~s(""), ~s("))
  end)
end

parse_row = fn line ->
  case parse_csv_line.(line) do
    [day, month, author, source, topic_en, topic_it, text_en, text_it] ->
      %{
        day: String.to_integer(day),
        month: String.to_integer(month),
        author: author,
        source: source,
        topic_en: topic_en,
        topic_it: topic_it,
        text_en: text_en,
        text_it: text_it
      }

    _ ->
      raise "Invalid CSV row: #{line}"
  end
end

quotes_attrs =
  csv_path
  |> File.stream!()
  |> Stream.drop(1)
  |> Stream.map(&String.trim/1)
  |> Enum.reject(&(&1 == ""))
  |> Enum.map(parse_row)

Enum.each(quotes_attrs, fn attrs ->
  case Repo.get_by(Quote, day: attrs.day, month: attrs.month) do
    nil ->
      %Quote{}
      |> Quote.changeset(attrs)
      |> Repo.insert!()

    %Quote{} = quote ->
      quote
      |> Quote.changeset(attrs)
      |> Repo.update!()
  end
end)

IO.puts("Seed completed: #{length(quotes_attrs)} quotes processed from #{csv_path}")
