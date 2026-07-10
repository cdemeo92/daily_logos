defmodule DailyLogosWeb.Components.SocialIcon do
  @moduledoc """
  Social icon component backed by Bootstrap Icons.
  """
  use DailyLogosWeb, :html

  attr :name, :string, required: true
  attr :class, :string, default: "text-xl leading-none"

  def social_icon(assigns) do
    assigns = assign(assigns, :icon_class, "bi bi-#{assigns.name}")

    ~H"""
    <i class={[@icon_class, "inline-block align-middle", @class]} aria-hidden="true"></i>
    """
  end
end
