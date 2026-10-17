defmodule DailyLogos.Repo.Migrations.CreateUserIdentities do
  use Ecto.Migration

  def up do
    create table(:user_identities) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :provider_uid, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:user_identities, [:user_id])
    create unique_index(:user_identities, [:provider, :provider_uid])

    execute("ALTER TABLE public.user_identities ENABLE ROW LEVEL SECURITY")

    execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.user_identities FROM anon';
      END IF;

      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.user_identities FROM authenticated';
      END IF;
    END
    $$;
    """)
  end

  def down do
    drop table(:user_identities)
  end
end
