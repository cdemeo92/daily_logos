defmodule DailyLogos.Quotes.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quotes" do
    field :day, :integer
    field :month, :integer
    field :author, :string
    field :source, :string
    field :topic, :string
    field :text_en, :string
    field :text_it, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [:day, :month, :author, :source, :topic, :text_en, :text_it])
    |> validate_required([:day, :month, :author, :source, :topic, :text_en, :text_it])
  end
end
