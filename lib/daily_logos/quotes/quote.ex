defmodule DailyLogos.Quotes.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quotes" do
    field :day, :integer
    field :month, :integer
    field :author, :string
    field :source, :string
    field :topic_en, :string
    field :topic_it, :string
    field :text_en, :string
    field :text_it, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [:day, :month, :author, :source, :topic_en, :topic_it, :text_en, :text_it])
    |> validate_required([
      :day,
      :month,
      :author,
      :source,
      :topic_en,
      :topic_it,
      :text_en,
      :text_it
    ])
  end
end
