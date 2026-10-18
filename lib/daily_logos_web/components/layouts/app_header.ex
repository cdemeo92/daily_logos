defmodule DailyLogosWeb.Layouts.AppHeader do
  @moduledoc """
  Application header component with responsive navigation.

  - Logo + version always visible
  - Desktop (md+): shows primary navigation, account actions, and utility controls
  - Mobile: shows the brand, GitHub, and a button to open the navigation dialog
  """
  use Phoenix.Component
  use Gettext, backend: DailyLogosWeb.Gettext

  import DailyLogosWeb.CoreComponents
  import DailyLogosWeb.Components.ThemeToggle
  import DailyLogosWeb.Components.LocaleToggle
  import DailyLogosWeb.Components.SocialIcon
  import DailyLogosWeb.Components.DropdownMenu

  attr :current_scope, :map, default: nil

  @doc """
  Renders the application header with logo, version, and responsive menu.
  """
  def app_header(assigns) do
    assigns = assign(assigns, :logout_form, Phoenix.Component.to_form(%{}, as: :logout))

    ~H"""
    <header class="fixed inset-x-0 top-0 z-30 h-16 bg-base-100/95 backdrop-blur px-4 sm:px-6 lg:px-8 border-b border-base-300 dark:border-neutral-content/10">
      <div class="navbar mx-auto max-w-7xl">
        <div class="flex-1 lg:flex-none">
          <a
            href={DailyLogosWeb.LocalePaths.localized_path("/")}
            class="flex-1 flex w-fit items-center gap-2"
          >
            <img src="/images/logo.svg" width="36" alt="Daily Logos" />
            <span class="text-sm font-semibold">v{Application.spec(:daily_logos, :vsn)}</span>
          </a>
        </div>

        <a
          href="https://github.com/cdemeo92/daily_logos"
          class="mr-3 flex min-h-11 min-w-11 items-center justify-center text-base-content/70 hover:text-base-content transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary lg:hidden"
          aria-label={gettext("GitHub repository")}
        >
          <.social_icon name="github" class="text-2xl leading-none" />
        </a>

        <nav
          aria-label={gettext("Primary navigation")}
          class="hidden lg:flex lg:flex-1 lg:justify-center"
        >
          <ul class="flex flex-row gap-2 items-center">
            <li>
              <a
                href="/feedback"
                class="block py-3 px-2 text-base-content/70 hover:text-base-content transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
              >
                {gettext("Send feedback")}
              </a>
            </li>
            <li>
              <a
                href="/about"
                class="block py-3 px-2 text-base-content/70 hover:text-base-content transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
              >
                {gettext("About")}
              </a>
            </li>
            <li>
              <a
                href="/notifications"
                class="block py-3 px-2 text-base-content/70 hover:text-base-content transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
              >
                {gettext("Notifications")}
              </a>
            </li>
          </ul>
        </nav>

        <div class="hidden lg:flex lg:flex-none lg:gap-3 items-center">
          <%= if @current_scope && @current_scope.user do %>
            <.dropdown_menu
              id="account-menu"
              class="account-menu relative"
              label={gettext("Account navigation")}
              trigger_label={gettext("Account")}
            >
              <:trigger>
                <.icon name="hero-user-circle" class="size-7" />
                <.icon name="hero-chevron-down" class="size-3" />
              </:trigger>
              <li>
                <a
                  href="/users/settings"
                  class="block min-h-11 rounded px-3 py-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >
                  {gettext("Settings")}
                </a>
              </li>
              <li>
                <a
                  href="/users/account/privacy"
                  class="block min-h-11 rounded px-3 py-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >
                  {gettext("Privacy")}
                </a>
              </li>
              <li>
                <.form
                  for={@logout_form}
                  id="desktop-logout-form"
                  action="/users/log-out"
                  method="delete"
                >
                  <button
                    type="submit"
                    class="block min-h-11 w-full cursor-pointer rounded px-3 py-2 text-left text-error focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                  >
                    {gettext("Log out")}
                  </button>
                </.form>
              </li>
            </.dropdown_menu>
          <% else %>
            <a
              href="/users/log-in"
              class="block py-3 px-2 text-base-content/70 hover:text-base-content transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              {gettext("Log in")}
            </a>
            <a
              href="/users/register"
              class="block py-3 px-2 text-base-content/70 hover:text-base-content transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            >
              {gettext("Sign up")}
            </a>
          <% end %>

          <ul class="flex flex-row gap-2 items-center">
            <li>
              <a
                href="https://github.com/cdemeo92/daily_logos"
                class="flex min-h-11 min-w-11 items-center justify-center text-base-content/70 hover:text-base-content transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                aria-label={gettext("GitHub repository")}
              >
                <.social_icon name="github" class="text-2xl leading-none" />
                <span class="sr-only">GitHub</span>
              </a>
            </li>
            <li>
              <.theme_toggle id="theme-toggle-header" />
            </li>
            <li>
              <.locale_toggle id="locale-toggle-header" />
            </li>
          </ul>
        </div>

        <div class="lg:hidden flex-none">
          <button
            id="menu-toggle"
            type="button"
            class="flex min-h-11 min-w-11 cursor-pointer items-center justify-center text-base-content/70 hover:text-base-content transition-colors focus-visible:outline-none focus-visible:text-base-content"
            phx-hook="HamburgerMenu"
            aria-label={gettext("Open menu")}
            aria-expanded="false"
            aria-controls="mobile-menu"
            data-open-label={gettext("Open menu")}
            data-close-label={gettext("Close menu")}
          >
            <.icon name="hero-bars-3" class="size-6" />
          </button>
        </div>
      </div>
    </header>
    """
  end
end
