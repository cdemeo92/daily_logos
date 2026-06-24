defmodule DailyLogos.Repo do
  use Ecto.Repo,
    otp_app: :daily_logos,
    adapter: Ecto.Adapters.Postgres
end
