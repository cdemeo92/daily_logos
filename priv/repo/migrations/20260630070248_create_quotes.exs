defmodule DailyLogos.Repo.Migrations.CreateQuotes do
  use Ecto.Migration

  def change do
    create table(:quotes) do
      add :day, :integer
      add :month, :integer
      add :author, :string
      add :source, :string
      add :topic_en, :string
      add :topic_it, :string
      add :text_en, :string
      add :text_it, :string

      timestamps(type: :utc_datetime)
    end
  end
end
