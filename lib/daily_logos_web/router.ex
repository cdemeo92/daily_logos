defmodule DailyLogosWeb.Router do
  use DailyLogosWeb, :router

  import DailyLogosWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_current_scope_for_user
    plug DailyLogosWeb.Plugs.SetLocale
    # plug DailyLogosWeb.Plugs.SeoMeta
    plug :fetch_live_flash
    # plug :put_root_layout, html: {DailyLogosWeb.Layouts, :root}
    plug :protect_from_forgery
    plug DailyLogosWeb.Plugs.SecurityHeaders
  end

  pipeline :locale_redirect do
    plug DailyLogosWeb.Plugs.LocaleRedirect
  end

  pipeline :locale_set do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug DailyLogosWeb.Plugs.SecurityHeaders
  end

  pipeline :seo do
    plug DailyLogosWeb.Plugs.SeoMeta
    plug :put_root_layout, html: {DailyLogosWeb.Layouts, :root}
  end

  defp put_robots_noindex(conn, _opts),
    do: Plug.Conn.put_resp_header(conn, "x-robots-tag", "noindex, nofollow")

  pipeline :api do
    plug :accepts, ["json"]
    plug :put_robots_noindex
    plug OpenApiSpex.Plug.PutApiSpec, module: DailyLogosWeb.ApiSpec
  end

  scope "/", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo]

    get "/", PageController, :home
    get "/feedback", PageController, :feedback
    get "/about", PageController, :about
    get "/support", PageController, :support
    get "/privacy", PageController, :privacy

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
  end

  ## Authentication routes

  scope "/", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
  end

  scope "/", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo, :redirect_if_user_is_authenticated]

    post "/users/register", UserRegistrationController, :create
  end

  scope "/", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
  end

  scope "/", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo, :require_authenticated_user]

    put "/users/settings", UserSettingsController, :update
  end

  scope "/", DailyLogosWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo]

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/locale", DailyLogosWeb do
    pipe_through :locale_set

    post "/:locale", LocaleController, :set
  end

  scope "/api" do
    pipe_through :api

    if Application.compile_env(:daily_logos, :dev_routes) do
      get "/docs", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
      get "/openapi", OpenApiSpex.Plug.RenderSpec, []
    end

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
      pipe_through [:browser]

      live_dashboard "/dashboard", metrics: DailyLogosWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/:locale_prefix", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo]

    get "/", PageController, :home
    get "/about", PageController, :about
    get "/support", PageController, :support
    get "/feedback", PageController, :feedback
    get "/privacy", PageController, :privacy

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
  end

  scope "/:locale_prefix", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
  end

  scope "/:locale_prefix", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
  end

  scope "/:locale_prefix", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo]

    get "/:month/:day", PageController, :show
  end

  scope "/", DailyLogosWeb do
    pipe_through [:browser, :locale_redirect, :seo]

    get "/:month/:day", PageController, :show
    get "/*path", PageController, :not_found
  end
end
