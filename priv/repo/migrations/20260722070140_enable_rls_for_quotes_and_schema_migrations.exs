defmodule DailyLogos.Repo.Migrations.EnableRlsForQuotesAndSchemaMigrations do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY")
    execute("ALTER TABLE public.schema_migrations ENABLE ROW LEVEL SECURITY")
  end

  def down do
    execute("ALTER TABLE public.quotes DISABLE ROW LEVEL SECURITY")
    execute("ALTER TABLE public.schema_migrations DISABLE ROW LEVEL SECURITY")
  end
end
