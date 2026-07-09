defmodule DailyLogosWeb.Components.Placeholder do
  @moduledoc """
  Placeholder component for unavailable or work-in-progress content.
  """
  use Phoenix.Component
  use Gettext, backend: DailyLogosWeb.Gettext

  import DailyLogosWeb.CoreComponents

  attr :icon, :string, default: "hero-clock"
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :id, :string, default: "placeholder"
  attr :class, :string, default: ""

  def placeholder(assigns) do
    assigns =
      assigns
      |> assign(:title, assigns[:title] || gettext("Coming soon"))
      |> assign(
        :description,
        assigns[:description] || gettext("This section is not available yet.")
      )

    ~H"""
    <div
      id={@id}
      class={[
        "rounded-xl border border-base-300 p-10 text-center text-base-content/50 space-y-3",
        @class
      ]}
    >
      <.icon name={@icon} class="size-10 mx-auto opacity-40" />
      <p class="font-medium">{@title}</p>
      <p class="text-sm">{@description}</p>
    </div>
    """
  end
end
