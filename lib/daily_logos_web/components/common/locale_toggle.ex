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
      phx-hook=".LocaleToggle"
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

    <form id={"#{@id}-form-en"} method="post" action={~p"/locale/en"} class="hidden">
      <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
    </form>

    <form id={"#{@id}-form-it"} method="post" action={~p"/locale/it"} class="hidden">
      <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
    </form>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".LocaleToggle">
      export default {
        mounted() {
          const buttons = this.el.querySelectorAll('button');
          buttons.forEach(btn => {
            btn.addEventListener('click', (e) => {
              e.preventDefault();
              const locale = btn.dataset.phxLocale;
              this.el.setAttribute('data-locale', locale);
              setTimeout(() => {
                const form = document.getElementById(`${this.el.id}-form-${locale}`);
                if (form) form.submit();
              }, 300);
            });
          });
        }
      }
    </script>
    """
  end
end
