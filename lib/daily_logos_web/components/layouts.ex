defmodule DailyLogosWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use DailyLogosWeb, :html

  embed_templates "layouts/*"

  import DailyLogosWeb.Layouts.AppHeader

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen">
      <.app_header />
      <DailyLogosWeb.Layouts.MainMenu.main_menu_sidebar />

      <main class="flex-1 px-4 py-20 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-7xl space-y-4">
          {render_slot(@inner_block)}
        </div>
      </main>

      <footer class="border-t border-base-300 dark:border-neutral-content/10 dark:bg-[oklch(0.27_0.02_255.66)] px-4 py-4 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-7xl space-y-2">
          <div class="flex justify-between items-center gap-4">
            <span class="font-semibold text-base-content">Daily Logos</span>
            <div class="flex-1">
              <%!-- <.ad_slot id="footer" /> --%>
            </div>
            <a
              href="https://github.com/claudio-demeo/daily_logos"
              target="_blank"
              rel="noopener noreferrer"
              class="text-base-content/70 hover:text-base-content transition-colors"
            >
              GitHub
            </a>
          </div>
          <div>
            <span class="text-sm text-base-content/70">
              © Daily Logos
            </span>
          </div>
        </div>
      </footer>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
