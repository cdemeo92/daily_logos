defmodule DailyLogos.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def up do
    Oban.Migration.up()

    execute("ALTER TABLE public.oban_jobs ENABLE ROW LEVEL SECURITY")
    execute("ALTER TABLE public.oban_peers ENABLE ROW LEVEL SECURITY")

    execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.oban_jobs FROM anon';
        EXECUTE 'REVOKE ALL ON TABLE public.oban_peers FROM anon';
      END IF;

      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.oban_jobs FROM authenticated';
        EXECUTE 'REVOKE ALL ON TABLE public.oban_peers FROM authenticated';
      END IF;
    END
    $$;
    """)
  end

  def down, do: Oban.Migration.down()
end
