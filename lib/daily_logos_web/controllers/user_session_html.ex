defmodule DailyLogosWeb.UserSessionHTML do
  use DailyLogosWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:daily_logos, DailyLogos.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
