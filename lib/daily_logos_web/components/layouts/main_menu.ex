defmodule DailyLogosWeb.Layouts.MainMenu do
  @moduledoc """
  Mobile sidebar menu component.

  Displays as a fixed sidebar that slides in from the right on mobile devices.
  Contains GitHub link, theme/locale toggles, and custom menu links.
  """
  use Phoenix.Component

  import DailyLogosWeb.CoreComponents
  import DailyLogosWeb.Components.ThemeToggle
  import DailyLogosWeb.Components.LocaleToggle

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
      class="fixed top-0 right-0 h-screen w-64 bg-base-100 dark:bg-base-100 shadow-lg transform translate-x-full transition-transform duration-300 z-50 md:hidden overflow-y-auto"
    >
      <div class="p-4">
        <button
          id="menu-close"
          class="btn btn-ghost btn-circle ml-auto flex mb-4"
          phx-hook="MobileMenuClose"
        >
          <.icon name="hero-x-mark" class="size-6" />
        </button>

        <ul class="flex flex-col space-y-4">
          <li>
            <a
              href="https://github.com/cdemeo92/daily_logos"
              class="btn btn-ghost btn-block justify-start !hover:bg-transparent !hover:shadow-none !active:bg-transparent !focus:bg-transparent !focus:shadow-none !outline-none !ring-0 !border-0"
            >
              GitHub
            </a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <.locale_toggle id="locale-toggle-sidebar" />
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
