defmodule DailyLogos.Repo.Migrations.EnableRlsForQuotesAndSchemaMigrations do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY")

    execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.schema_migrations FROM anon';
      END IF;

      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.schema_migrations FROM authenticated';
      END IF;
    END
    $$;
    """)
  end

  def down do
    execute("ALTER TABLE public.quotes DISABLE ROW LEVEL SECURITY")
  end
end
