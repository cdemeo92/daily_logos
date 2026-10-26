defmodule DailyLogosWeb.TimezoneSelect do
  @moduledoc """
  Searchable IANA timezone selection with current UTC offsets.
  """

  use DailyLogosWeb, :html

  import DailyLogosWeb.DropdownSelect

  attr :field, Phoenix.HTML.FormField, required: true
  attr :timezones, :list, required: true
  attr :suggest_browser, :boolean, default: true

  def timezone_select(assigns) do
    now = DateTime.utc_now()

    assigns =
      assign(assigns, :options, Enum.map(assigns.timezones, &{timezone_label(&1, now), &1}))

    ~H"""
    <.dropdown_select
      field={@field}
      options={@options}
      label={gettext("Time zone")}
      prompt={gettext("Select time zone")}
      searchable
      search_label={gettext("Search time zones")}
      empty_label={gettext("No time zones found.")}
      suggest_browser={@suggest_browser}
    />
    """
  end

  defp timezone_label(timezone, now) do
    local = DateTime.shift_zone!(now, timezone)
    offset = local.utc_offset + local.std_offset
    sign = if offset < 0, do: "-", else: "+"
    minutes = div(abs(offset), 60)
    hours_label = minutes |> div(60) |> to_string() |> String.pad_leading(2, "0")
    minutes_label = minutes |> rem(60) |> to_string() |> String.pad_leading(2, "0")

    "#{timezone} (UTC#{sign}#{hours_label}:#{minutes_label})"
  end
end
