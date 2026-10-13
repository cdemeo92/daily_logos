defmodule DailyLogosWeb.Components.LocaleToggle do
  @moduledoc """
  Locale toggle component for switching between EN and IT languages.
  """
  use DailyLogosWeb, :html

  attr :id, :string, default: "locale-toggle", doc: "unique identifier for the toggle"

  def locale_toggle(assigns) do
    assigns = assign(assigns, :current_locale, Gettext.get_locale(DailyLogosWeb.Gettext))

    ~H"""
    <div
      id={@id}
      data-locale={@current_locale}
      data-csrf={get_csrf_token()}
      role="group"
      aria-label={gettext("Language")}
      class="card relative flex flex-row items-center overflow-hidden rounded-full border-2 border-base-300 bg-base-300"
    >
      <div class="absolute h-full w-1/2 rounded-full border border-base-200 bg-base-100 brightness-200 left-0 [[data-locale=it]_&]:left-1/2 transition-[left] duration-300 ease-out" />

      <button
        type="button"
        class={[
          "relative z-10 flex min-h-11 min-w-11 w-1/2 cursor-pointer items-center justify-center px-3 py-2 text-base leading-none font-medium focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
          @current_locale == "en" && "font-semibold opacity-100",
          @current_locale != "en" && "opacity-70 hover:opacity-100"
        ]}
        aria-label={gettext("Switch language to English")}
        aria-pressed={to_string(@current_locale == "en")}
        data-phx-locale="en"
      >
        EN
      </button>

      <button
        type="button"
        class={[
          "relative z-10 flex min-h-11 min-w-11 w-1/2 cursor-pointer items-center justify-center px-3 py-2 text-base leading-none font-medium focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary",
          @current_locale == "it" && "font-semibold opacity-100",
          @current_locale != "it" && "opacity-70 hover:opacity-100"
        ]}
        aria-label={gettext("Switch language to Italian")}
        aria-pressed={to_string(@current_locale == "it")}
        data-phx-locale="it"
      >
        IT
      </button>
    </div>
    """
  end
end
