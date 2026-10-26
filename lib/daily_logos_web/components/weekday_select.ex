defmodule DailyLogosWeb.WeekdaySelect do
  @moduledoc """
  Circular multi-select controls for ISO weekdays.
  """

  use DailyLogosWeb, :html

  attr :field, Phoenix.HTML.FormField, required: true
  attr :id, :string, required: true
  attr :label, :string, required: true

  def weekday_select(assigns) do
    assigns = assign(assigns, :weekdays, weekdays())

    ~H"""
    <fieldset
      id={@id}
      data-weekday-select
      aria-describedby={@field.errors != [] && "#{@id}-error"}
    >
      <legend class="mb-3 text-sm font-medium">{@label}</legend>
      <.input type="hidden" name={"#{@field.name}[]"} value="" />
      <div class="grid w-full max-w-[26rem] grid-cols-7 gap-1 sm:gap-3">
        <div :for={{day, short_name, full_name} <- @weekdays} class="min-w-0">
          <button
            type="button"
            id={"#{@id}-#{day}"}
            data-weekday-toggle
            data-weekday-value-id={"#{@id}-value-#{day}"}
            aria-label={full_name}
            aria-pressed={to_string(selected?(@field.value, day))}
            class="flex aspect-square w-full items-center justify-center rounded-full border border-base-300 bg-base-100 text-xs font-medium text-base-content/75 shadow-sm transition-colors hover:border-primary/50 hover:bg-base-200 aria-pressed:border-primary aria-pressed:bg-primary aria-pressed:text-primary-content aria-pressed:shadow-md aria-pressed:ring-2 aria-pressed:ring-primary/20 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-primary sm:text-sm"
          >{short_name}</button>
          <.input
            type="hidden"
            id={"#{@id}-value-#{day}"}
            name={"#{@field.name}[]"}
            value={day}
            disabled={!selected?(@field.value, day)}
          />
        </div>
      </div>
      <p :if={@field.errors != []} id={"#{@id}-error"} class="mt-3 text-sm text-error">
        {gettext("Select at least one valid day.")}
      </p>
    </fieldset>
    """
  end

  defp weekdays do
    [
      {1, gettext("Mon"), gettext("Monday")},
      {2, gettext("Tue"), gettext("Tuesday")},
      {3, gettext("Wed"), gettext("Wednesday")},
      {4, gettext("Thu"), gettext("Thursday")},
      {5, gettext("Fri"), gettext("Friday")},
      {6, gettext("Sat"), gettext("Saturday")},
      {7, gettext("Sun"), gettext("Sunday")}
    ]
  end

  defp selected?(value, day) when is_list(value),
    do: Enum.any?(value, &(to_string(&1) == to_string(day)))

  defp selected?(_value, _day), do: false
end
