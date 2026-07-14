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
      class="card relative flex flex-row items-center overflow-hidden rounded-full border-2 border-base-300 bg-base-300"
    >
      <div class="absolute h-full w-1/2 rounded-full border border-base-200 bg-base-100 brightness-200 left-0 [[data-locale=it]_&]:left-1/2 transition-[left] duration-300 ease-out" />

      <button
        type="button"
        class={[
          "relative z-10 flex w-1/2 cursor-pointer items-center justify-center px-3 py-2 text-base leading-none font-medium",
          @current_locale == "en" && "font-semibold opacity-100",
          @current_locale != "en" && "opacity-70 hover:opacity-100"
        ]}
        data-phx-locale="en"
      >
        EN
      </button>

      <button
        type="button"
        class={[
          "relative z-10 flex w-1/2 cursor-pointer items-center justify-center px-3 py-2 text-base leading-none font-medium",
          @current_locale == "it" && "font-semibold opacity-100",
          @current_locale != "it" && "opacity-70 hover:opacity-100"
        ]}
        data-phx-locale="it"
      >
        IT
      </button>
    </div>

    <script>
      (() => {
        const localeToggle = document.querySelector('#<%= @id %>');
        if (!localeToggle || localeToggle.dataset.init === 'true') return;

        localeToggle.dataset.init = 'true';

        const csrf = localeToggle.dataset.csrf;

        localeToggle.querySelectorAll('button').forEach(btn => {
          btn.addEventListener('click', e => {
            e.preventDefault();
            const locale = btn.dataset.phxLocale;

            localeToggle.dataset.locale = locale;

            setTimeout(async () => {
              const response = await fetch(`/locale/${locale}`, {
                method: 'POST',
                headers: { 'x-csrf-token': csrf },
                credentials: 'same-origin',
                redirect: 'follow'
              });

              if (response.redirected) {
                window.location.assign(response.url);
              } else {
                window.location.reload();
              }
            }, 300);
          });
        });
      })();
    </script>
    """
  end
end
