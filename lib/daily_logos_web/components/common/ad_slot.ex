defmodule DailyLogosWeb.Components.AdSlot do
  @moduledoc """
  Ad slot component for Google AdSense integration.

  """
  use Phoenix.Component

  @client_id System.get_env("GOOGLE_ADSENSE_CLIENT_ID")
  @ad_units %{
    "footer_center" => System.get_env("GOOGLE_ADSENSE_UNIT_FOOTER")
  }

  attr :position, :string,
    required: true,
    doc: "Which ad slot to display (e.g., 'footer_center')"

  @doc """
  Renders a Google AdSense ad slot.

  The position determines which ad unit ID to use.
  If not configured, displays a yellow placeholder.

  ## Examples

      <.ad_slot position="footer_center" />
  """
  def ad_slot(assigns) do
    ad_unit_id = Map.get(@ad_units, assigns.position)
    min_height = get_min_height(assigns.position)

    assigns =
      assign(assigns,
        ad_unit_id: ad_unit_id,
        min_height: min_height,
        client_id: @client_id
      )

    ~H"""
    <div id={"ad-slot-#{@position}"} class="ad-slot ad-slot-{@position}" phx-update="ignore">
      <%= if @ad_unit_id do %>
        <script
          async
          src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={@client_id}"
        >
        </script>
        <ins
          class="adsbygoogle"
          style="display:block"
          data-ad-client={@client_id}
          data-ad-slot={@ad_unit_id}
          data-ad-format="auto"
          data-full-width-responsive="true"
        >
        </ins>
        <script>
          (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
      <% else %>
        <div
          style={"min-height: #{@min_height}px"}
          class="bg-yellow-100 border-2 border-yellow-400 rounded flex items-center justify-center"
        >
          <div class="text-center text-yellow-900">
            <p class="font-semibold text-sm">Ad Slot: {@position}</p>
            <p class="text-xs">Configure Unit ID in ad_slot.ex</p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_min_height("footer_center"), do: 60
  defp get_min_height(_), do: 100
end
