defmodule DailyLogosWeb.ApiSpec do
  @moduledoc """
  OpenAPI specification root for Daily Logos API.
  """

  alias DailyLogosWeb.Router
  alias OpenApiSpex.{Info, OpenApi, Paths, Server}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [%Server{url: "/"}],
      info: %Info{title: "Daily Logos API", version: "1.0"},
      paths: Paths.from_router(Router)
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
