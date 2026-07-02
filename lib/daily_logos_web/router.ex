defmodule DailyLogosWeb.Router do
  use DailyLogosWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug DailyLogosWeb.Plugs.Locale
    plug :fetch_live_flash
    plug :put_root_layout, html: {DailyLogosWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: DailyLogosWeb.ApiSpec
  end

  scope "/", DailyLogosWeb do
    pipe_through :browser

    get "/", PageController, :home
    post "/locale/:locale", LocaleController, :set
  end

  scope "/api" do
    pipe_through :api

    get "/docs", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []

    scope "/v1", DailyLogosWeb do
      get "/quotes", QuoteController, :show
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:daily_logos, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DailyLogosWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
