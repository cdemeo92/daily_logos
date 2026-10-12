defmodule DailyLogosWeb.Plugs.AuthRateLimit do
  @moduledoc """
  Limits registration and magic-link requests before account lookup or email delivery.
  """

  use Gettext, backend: DailyLogosWeb.Gettext

  import Plug.Conn

  alias DailyLogos.AuthRateLimiter

  @defaults [window_ms: :timer.minutes(1), email_limit: 5, ip_limit: 50]

  def init(opts), do: Keyword.merge(@defaults, opts)

  def call(%{method: "POST", params: %{"user" => %{"email" => email} = params}} = conn, opts)
      when is_binary(email) do
    if conn.request_path == "/users/register" ||
         (conn.request_path == "/users/log-in" && !Map.has_key?(params, "password") &&
            !Map.has_key?(params, "token")) do
      limit(conn, email, opts)
    else
      conn
    end
  end

  def call(conn, _opts), do: conn

  defp limit(conn, email, opts) do
    email_key = :crypto.hash(:sha256, email |> String.trim() |> String.downcase())

    with {:allow, _count} <-
           AuthRateLimiter.hit({:ip, conn.remote_ip}, opts[:window_ms], opts[:ip_limit]),
         {:allow, _count} <-
           AuthRateLimiter.hit({:email, email_key}, opts[:window_ms], opts[:email_limit]) do
      conn
    else
      {:deny, retry_after} ->
        conn
        |> put_resp_header("retry-after", Integer.to_string(max(div(retry_after + 999, 1000), 1)))
        |> put_resp_content_type("text/plain")
        |> send_resp(429, gettext("Too many requests. Please try again later."))
        |> halt()
    end
  end
end
