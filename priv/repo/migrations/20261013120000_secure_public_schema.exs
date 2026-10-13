defmodule DailyLogos.Repo.Migrations.SecurePublicSchema do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE public.users ENABLE ROW LEVEL SECURITY")
    execute("ALTER TABLE public.users_tokens ENABLE ROW LEVEL SECURITY")

    execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.users FROM anon';
        EXECUTE 'REVOKE ALL ON TABLE public.users_tokens FROM anon';
      END IF;

      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.users FROM authenticated';
        EXECUTE 'REVOKE ALL ON TABLE public.users_tokens FROM authenticated';
      END IF;
    END
    $$;
    """)

    execute("""
    CREATE POLICY quotes_public_read
    ON public.quotes
    FOR SELECT
    USING (true)
    """)
  end

  def down do
    execute("DROP POLICY quotes_public_read ON public.quotes")
    execute("ALTER TABLE public.users_tokens DISABLE ROW LEVEL SECURITY")
    execute("ALTER TABLE public.users DISABLE ROW LEVEL SECURITY")
  end
end
