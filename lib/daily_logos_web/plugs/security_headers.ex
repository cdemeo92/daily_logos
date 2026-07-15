defmodule DailyLogosWeb.Plugs.SecurityHeaders do
  @moduledoc """
  Applies secure browser headers with a centralized Content Security Policy.
  """
  import Phoenix.Controller, only: [put_secure_browser_headers: 2]

  @base_csp [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' https://www.googletagmanager.com https://www.google-analytics.com",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://www.googletagmanager.com",
    "font-src 'self' https://fonts.gstatic.com",
    "img-src 'self' data: https:",
    "connect-src 'self' https://www.google-analytics.com https://region1.analytics.google.com https://region1.google-analytics.com https://stats.g.doubleclick.net",
    "frame-src 'self' https://docs.google.com https://www.googletagmanager.com"
  ]

  @csp Enum.join(
         if(Mix.env() == :prod,
           do: ["upgrade-insecure-requests"] ++ @base_csp,
           else: @base_csp
         ),
         "; "
       )

  def init(opts), do: opts

  def call(conn, _opts) do
    put_secure_browser_headers(conn, %{"content-security-policy" => @csp})
  end
end
