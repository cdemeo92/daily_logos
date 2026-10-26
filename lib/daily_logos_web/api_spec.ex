defmodule DailyLogosWeb.ApiSpec do
  @moduledoc """
  OpenAPI specification root for Daily Logos API.
  """

  alias DailyLogosWeb.Router
  alias OpenApiSpex.{Components, Info, OpenApi, Paths, SecurityScheme, Server}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [%Server{url: "/"}],
      info: %Info{title: "Daily Logos API", version: "1.0"},
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{
          "sessionCookie" => %SecurityScheme{
            type: "apiKey",
            in: "cookie",
            name: "_daily_logos_key",
            description: "Authenticated Daily Logos browser session cookie."
          },
          "csrfToken" => %SecurityScheme{
            type: "apiKey",
            in: "header",
            name: "x-csrf-token",
            description: "CSRF token rendered in the authenticated Notifications form."
          }
        }
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
