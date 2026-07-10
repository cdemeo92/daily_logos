defmodule DailyLogosWeb.Layouts.AppHeader do
  @moduledoc """
  Application header component with responsive navigation.

  - Logo + version always visible
  - Desktop (md+): shows GitHub link + theme/locale toggles inline
  - Mobile: shows hamburger button to open sidebar menu
  """
  use Phoenix.Component
  use Gettext, backend: DailyLogosWeb.Gettext

  import DailyLogosWeb.CoreComponents
  import DailyLogosWeb.Components.ThemeToggle
  import DailyLogosWeb.Components.LocaleToggle
  import DailyLogosWeb.Components.SocialIcon

  @doc """
  Renders the application header with logo, version, and responsive menu.
  """
  def app_header(assigns) do
    ~H"""
    <header class="px-4 sm:px-6 lg:px-8 border-b border-base-300 dark:border-neutral-content/10">
      <div class="navbar mx-auto max-w-7xl">
        <div class="flex-1 md:flex-none">
          <a href="/" class="flex-1 flex w-fit items-center gap-2">
            <img src="/images/logo.svg" width="36" alt="Daily Logos" />
            <span class="text-sm font-semibold">v{Application.spec(:daily_logos, :vsn)}</span>
          </a>
        </div>

        <nav aria-label="Primary navigation" class="hidden md:flex md:flex-1 md:justify-center">
          <ul class="flex flex-row gap-2 items-center">
            <li>
              <a
                href="/feedback"
                class="block text-base-content/70 hover:text-base-content transition-colors py-3 px-2"
              >
                {gettext("Send feedback")}
              </a>
            </li>
            <li>
              <a
                href="/support"
                class="block text-base-content/70 hover:text-base-content transition-colors py-3 px-2"
              >
                {gettext("Support")}
              </a>
            </li>
            <li>
              <a
                href="/about"
                class="block text-base-content/70 hover:text-base-content transition-colors py-3 px-2"
              >
                {gettext("About")}
              </a>
            </li>
          </ul>
        </nav>

        <div class="hidden md:flex md:flex-none md:gap-4 items-center">
          <ul class="flex flex-row gap-2 items-center">
            <li>
              <a
                href="https://github.com/cdemeo92/daily_logos"
                class="flex items-center text-base-content/70 hover:text-base-content transition-colors py-3 px-2"
                aria-label="GitHub repository"
              >
                <.social_icon name="github" class="text-2xl leading-none" />
                <span class="sr-only">GitHub</span>
              </a>
            </li>
            <li>
              <.theme_toggle />
            </li>
            <li>
              <.locale_toggle id="locale-toggle-header" />
            </li>
          </ul>
        </div>

        <div class="md:hidden flex-none">
          <button
            id="menu-toggle"
            class="btn btn-ghost btn-circle"
            phx-hook="HamburgerMenu"
            aria-label="Open menu"
          >
            <.icon name="hero-bars-3" class="size-6" />
          </button>
        </div>
      </div>
    </header>
    """
  end
end
