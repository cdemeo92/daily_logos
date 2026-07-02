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

quotes_attrs =
  csv_path
  |> File.stream!()
  |> Stream.drop(1)
  |> Stream.map(&String.trim/1)
  |> Enum.reject(&(&1 == ""))
  |> Enum.map(fn line ->
    case String.split(line, ",", parts: 8) do
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
  end)

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
