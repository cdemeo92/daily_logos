defmodule DailyLogosWeb.Components.DropdownMenu do
  @moduledoc """
  Reusable accessible dropdown navigation component.

  The trigger and all menu entries or actions are supplied by the caller.
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :trigger_label, :string, required: true
  attr :class, :string, default: "relative"

  attr :trigger_class, :string,
    default:
      "flex min-h-11 min-w-11 cursor-pointer items-center justify-center gap-1 rounded px-2 text-base-content/70 transition-colors hover:text-base-content focus-visible:outline-none focus-visible:text-base-content list-none [&::-webkit-details-marker]:hidden"

  attr :panel_class, :string,
    default:
      "absolute right-0 top-full z-50 mt-2 min-w-48 rounded-md border border-base-300 bg-base-100 p-2 shadow-lg"

  slot :trigger, required: true
  slot :inner_block, required: true

  def dropdown_menu(assigns) do
    ~H"""
    <details id={@id} class={@class}>
      <summary class={@trigger_class} aria-label={@trigger_label} title={@trigger_label}>
        {render_slot(@trigger)}
      </summary>
      <nav aria-label={@label} class={@panel_class}>
        <ul class="space-y-1">
          {render_slot(@inner_block)}
        </ul>
      </nav>
    </details>
    """
  end
end
