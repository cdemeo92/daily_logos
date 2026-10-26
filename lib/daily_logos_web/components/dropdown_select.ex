defmodule DailyLogosWeb.DropdownSelect do
  @moduledoc """
  Accessible dropdown selection with optional text search.
  """

  use DailyLogosWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :options, :list, required: true
  attr :label, :string, required: true
  attr :prompt, :string, required: true
  attr :searchable, :boolean, default: false
  attr :search_label, :string, default: nil
  attr :empty_label, :string, default: nil
  attr :suggest_browser, :boolean, default: false
  attr :class, :string, default: ""

  def dropdown_select(assigns) do
    options =
      [
        {assigns.prompt, ""}
        | Enum.map(assigns.options, fn
            {label, value} -> {label, to_string(value)}
            value -> {to_string(value), to_string(value)}
          end)
      ]

    selected =
      Enum.find_value(options, assigns.field.value, fn {label, value} ->
        if value == to_string(assigns.field.value), do: label
      end)

    assigns =
      assigns
      |> assign(:options, options)
      |> assign(:selected_label, selected)

    ~H"""
    <div
      id={"#{@field.id}-select"}
      class={["relative min-w-0", @class]}
      data-dropdown-select
      data-suggest-browser={to_string(@suggest_browser)}
    >
      <label id={"#{@field.id}-label"} for={"#{@field.id}-trigger"} class="mb-1 block text-sm">
        {@label}
      </label>
      <.input field={@field} type="hidden" />
      <button
        type="button"
        id={"#{@field.id}-trigger"}
        data-dropdown-trigger
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls={"#{@field.id}-options"}
        aria-labelledby={"#{@field.id}-label #{@field.id}-value"}
        aria-describedby={@field.errors != [] && "#{@field.id}-errors"}
        class="flex min-h-11 w-full items-center justify-between gap-2 rounded-md border border-base-300 bg-base-100 px-3 py-2 text-left text-base focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
      >
        <span id={"#{@field.id}-value"} data-dropdown-label class="min-w-0 break-words">
          {@selected_label || @prompt}
        </span>
        <.icon name="hero-chevron-down" class="size-4 shrink-0" />
      </button>
      <div
        data-dropdown-panel
        hidden
        class="absolute inset-x-0 top-full z-30 mt-1 overflow-hidden rounded-md border border-base-300 bg-base-100 shadow-lg"
      >
        <div :if={@searchable} class="border-b border-base-300 p-2">
          <.input
            id={"#{@field.id}-search"}
            name={nil}
            type="search"
            value=""
            role="combobox"
            aria-label={@search_label}
            aria-autocomplete="list"
            aria-controls={"#{@field.id}-options"}
            aria-expanded="false"
            autocomplete="off"
            data-dropdown-search
            class="min-h-11 w-full rounded-md border border-base-300 bg-base-100 px-3 text-base"
          />
        </div>
        <div
          id={"#{@field.id}-options"}
          role="listbox"
          tabindex="-1"
          aria-labelledby={"#{@field.id}-label"}
          class="max-h-60 overflow-y-auto overscroll-contain p-1 focus:outline-none"
        >
          <button
            :for={{{label, value}, index} <- Enum.with_index(@options)}
            id={"#{@field.id}-option-#{index}"}
            type="button"
            role="option"
            tabindex="-1"
            aria-selected={to_string(value == to_string(@field.value))}
            data-dropdown-option
            data-value={value}
            class="block min-h-11 w-full break-words rounded px-3 py-2 text-left text-sm hover:bg-base-200 aria-selected:font-semibold data-[active=true]:bg-base-200"
          >{label}</button>
        </div>
        <p :if={@searchable} data-dropdown-empty hidden role="status" class="px-3 py-3 text-sm">
          {@empty_label}
        </p>
      </div>
      <div :if={@field.errors != []} id={"#{@field.id}-errors"} class="mt-2 text-sm text-error">
        <p :for={error <- @field.errors}>{translate_error(error)}</p>
      </div>
    </div>
    """
  end
end
