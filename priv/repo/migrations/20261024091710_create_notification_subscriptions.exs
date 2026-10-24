defmodule DailyLogos.Repo.Migrations.CreateNotificationSubscriptions do
  use Ecto.Migration

  def up do
    create table(:notification_subscriptions) do
      add :provider, :string, null: false
      add :name, :string
      add :weekdays, {:array, :integer}
      add :local_hour, :integer
      add :timezone, :string
      add :language, :string
      add :enabled, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notification_subscriptions, [:user_id])

    create unique_index(:notification_subscriptions, [:user_id],
             where: "provider = 'email'",
             name: :notification_subscriptions_one_email_per_user
           )

    create constraint(:notification_subscriptions, :notification_subscriptions_provider_check,
             check: "provider IN ('email', 'slack', 'discord')"
           )

    create constraint(:notification_subscriptions, :notification_subscriptions_hour_check,
             check: "local_hour >= 0 AND local_hour <= 23"
           )

    execute("ALTER TABLE public.notification_subscriptions ENABLE ROW LEVEL SECURITY")

    execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.notification_subscriptions FROM anon';
      END IF;

      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE ALL ON TABLE public.notification_subscriptions FROM authenticated';
      END IF;
    END
    $$;
    """)
  end

  def down do
    drop table(:notification_subscriptions)
  end
end
