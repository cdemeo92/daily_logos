defmodule DailyLogosWeb.Layouts.MainMenu do
  @moduledoc """
  Mobile sidebar menu component.

  Displays as an accessible modal sidebar that slides in from the right on mobile.
  """
  use Phoenix.Component
  use Gettext, backend: DailyLogosWeb.Gettext

  import DailyLogosWeb.CoreComponents
  import DailyLogosWeb.Components.ThemeToggle
  import DailyLogosWeb.Components.LocaleToggle
  import DailyLogosWeb.Components.SocialIcon

  attr :current_scope, :map, default: nil

  @doc """
  Renders the mobile sidebar menu.

  Only visible on mobile devices, slides in from the right.
  """
  def main_menu_sidebar(assigns) do
    assigns = assign(assigns, :logout_form, Phoenix.Component.to_form(%{}, as: :logout))

    ~H"""
    <div
      id="mobile-menu-overlay"
      class="hidden fixed inset-0 bg-black/50 z-40 lg:hidden"
      phx-hook="MobileMenuOverlay"
      aria-hidden="true"
    >
    </div>

    <div
      id="mobile-menu"
      class="fixed top-0 right-0 h-screen w-[min(20rem,calc(100vw-2rem))] bg-base-100 shadow-lg transform translate-x-full transition-transform duration-300 motion-reduce:transition-none z-50 lg:hidden overflow-y-auto flex flex-col"
      role="dialog"
      aria-modal="true"
      aria-label={gettext("Mobile navigation")}
      aria-hidden="true"
      inert
      tabindex="-1"
    >
      <div class="border-b border-base-300 dark:border-neutral-content/10 p-4 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <a
            href="/"
            class="flex min-h-11 items-center gap-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            <img src="/images/logo.svg" width="32" alt="Daily Logos" />
            <span class="text-xs font-semibold">v{Application.spec(:daily_logos, :vsn)}</span>
          </a>
          <a
            href="https://github.com/cdemeo92/daily_logos"
            class="flex min-h-11 min-w-11 items-center justify-center text-base-content/70 hover:text-base-content transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
            aria-label="GitHub repository"
          >
            <.social_icon name="github" class="text-[1.5rem] leading-none" />
            <span class="sr-only">GitHub</span>
          </a>
        </div>
        <div class="flex items-center">
          <button
            id="menu-close"
            type="button"
            class="flex min-h-11 min-w-11 cursor-pointer items-center justify-center text-base-content/70 hover:text-base-content transition-colors focus-visible:outline-none focus-visible:text-base-content"
            phx-hook="MobileMenuClose"
            aria-label={gettext("Close menu")}
          >
            <.icon name="hero-x-mark" class="size-6" />
          </button>
        </div>
      </div>

      <div class="flex min-h-0 flex-1 flex-col overflow-y-auto">
        <nav aria-label={gettext("Primary navigation")} class="p-4">
          <ul>
            <%= if @current_scope && @current_scope.user do %>
              <li>
                <a
                  href="/notifications"
                  class="block min-h-11 py-3 px-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >{gettext("Notifications")}</a>
              </li>
              <li>
                <a
                  href="/users/settings"
                  class="block min-h-11 py-3 px-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >{gettext("Settings")}</a>
              </li>
              <li>
                <a
                  href="/users/account/privacy"
                  class="block min-h-11 py-3 px-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >{gettext("Privacy")}</a>
              </li>
              <li>
                <.form
                  for={@logout_form}
                  id="mobile-logout-form"
                  action="/users/log-out"
                  method="delete"
                >
                  <button
                    type="submit"
                    class="block min-h-11 w-full cursor-pointer py-3 px-2 text-left text-error focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                  >
                    {gettext("Log out")}
                  </button>
                </.form>
              </li>
            <% else %>
              <li>
                <a
                  href="/users/log-in"
                  class="block min-h-11 py-3 px-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >{gettext("Log in")}</a>
              </li>
              <li>
                <a
                  href="/users/register"
                  class="block min-h-11 py-3 px-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >{gettext("Sign up")}</a>
              </li>
              <li>
                <a
                  href="/notifications"
                  class="block min-h-11 py-3 px-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
                >
                  {gettext("Notifications")}
                </a>
              </li>
            <% end %>
          </ul>
        </nav>

        <nav aria-label={gettext("Information")} class="mt-auto p-4">
          <ul>
            <li>
              <a
                href="/feedback"
                class="block min-h-11 py-3 px-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
              >{gettext("Send feedback")}</a>
            </li>
            <li>
              <a
                href="/about"
                class="block min-h-11 py-3 px-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
              >{gettext("About")}</a>
            </li>
          </ul>
        </nav>
      </div>

      <div class="border-t border-base-300 space-y-6 p-4">
        <div>
          <p id="mobile-theme-label" class="text-xs font-semibold text-base-content/60 mb-3">
            {gettext("Theme")}
          </p>
          <.theme_toggle id="theme-toggle-sidebar" />
        </div>
        <div>
          <p class="text-xs font-semibold text-base-content/60 mb-3">{gettext("Language")}</p>
          <.locale_toggle id="locale-toggle-sidebar" />
        </div>
      </div>
    </div>
    """
  end
end
