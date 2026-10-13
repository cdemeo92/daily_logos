defmodule DailyLogosWeb.Components.ThemeToggle do
  @moduledoc """
  Theme toggle component with System/Light/Dark options.
  """
  use DailyLogosWeb, :html

  attr :id, :string, default: "theme-toggle"

  def theme_toggle(assigns) do
    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={gettext("Theme")}
      phx-hook="ThemeToggle"
      class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full"
    >
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        type="button"
        aria-label={gettext("Use system theme")}
        title={gettext("Use system theme")}
        aria-pressed="false"
        class="flex min-h-11 min-w-11 justify-center items-center p-2 cursor-pointer w-1/3 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        type="button"
        aria-label={gettext("Use light theme")}
        title={gettext("Use light theme")}
        aria-pressed="false"
        class="flex min-h-11 min-w-11 justify-center items-center p-2 cursor-pointer w-1/3 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        type="button"
        aria-label={gettext("Use dark theme")}
        title={gettext("Use dark theme")}
        aria-pressed="false"
        class="flex min-h-11 min-w-11 justify-center items-center p-2 cursor-pointer w-1/3 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
