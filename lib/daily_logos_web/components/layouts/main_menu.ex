defmodule DailyLogosWeb.Layouts.MainMenu do
  @moduledoc """
  Mobile sidebar menu component.

  Displays as a fixed sidebar that slides in from the right on mobile devices.
  Contains GitHub link, theme/locale toggles, and custom menu links.
  """
  use Phoenix.Component
  use Gettext, backend: DailyLogosWeb.Gettext

  import DailyLogosWeb.CoreComponents
  import DailyLogosWeb.Components.ThemeToggle
  import DailyLogosWeb.Components.LocaleToggle
  import DailyLogosWeb.Components.SocialIcon

  @doc """
  Renders the mobile sidebar menu.

  Only visible on mobile devices, slides in from the right.
  """
  def main_menu_sidebar(assigns) do
    ~H"""
    <div
      id="mobile-menu-overlay"
      class="hidden fixed inset-0 bg-black/50 z-40 md:hidden"
      phx-hook="MobileMenuOverlay"
    >
    </div>

    <div
      id="mobile-menu"
      class="fixed top-0 right-0 h-screen w-64 bg-base-100 dark:bg-base-100 shadow-lg transform translate-x-full transition-transform duration-300 z-50 md:hidden overflow-y-auto flex flex-col"
    >
      <div class="border-b border-base-300 dark:border-neutral-content/10 p-4 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <a href="./" class="flex items-center gap-2" aria-label="Home">
            <img src="/images/logo.svg" width="32" alt="Logo" />
            <span class="text-xs font-semibold">v{Application.spec(:daily_logos, :vsn)}</span>
          </a>
          <a
            href="https://github.com/cdemeo92/daily_logos"
            class="flex items-center text-base-content/70 hover:text-base-content transition-colors"
            aria-label="GitHub repository"
          >
            <.social_icon name="github" class="text-[1.5rem] leading-none" />
            <span class="sr-only">GitHub</span>
          </a>
        </div>
        <div class="flex items-center">
          <button
            id="menu-close"
            class="btn btn-ghost btn-circle !hover:bg-transparent !hover:shadow-none !active:bg-transparent !focus:bg-transparent !focus:shadow-none"
            phx-hook="MobileMenuClose"
            aria-label="Close menu"
          >
            <.icon name="hero-x-mark" class="size-6" />
          </button>
        </div>
      </div>

      <div class="flex-1 p-4">
        <nav aria-label="Menu">
          <a
            href="./feedback"
            class="block text-base-content/70 hover:text-base-content transition-colors py-3 px-2"
          >
            {gettext("Send feedback")}
          </a>
          <a
            href="./support"
            class="block text-base-content/70 hover:text-base-content transition-colors py-3 px-2"
          >
            {gettext("Support")}
          </a>
          <a
            href="./about"
            class="block text-base-content/70 hover:text-base-content transition-colors py-3 px-2"
          >
            {gettext("About")}
          </a>
        </nav>
      </div>

      <div class="border-t border-base-300 dark:border-neutral-content/10 space-y-6 p-4">
        <div>
          <label class="text-xs font-semibold text-base-content/60 block mb-3">THEME</label>
          <.theme_toggle />
        </div>
        <div>
          <label class="text-xs font-semibold text-base-content/60 block mb-3">LANGUAGE</label>
          <.locale_toggle id="locale-toggle-sidebar" />
        </div>
      </div>
    </div>
    """
  end
end
