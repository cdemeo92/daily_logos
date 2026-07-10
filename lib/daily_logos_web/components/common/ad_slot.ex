defmodule DailyLogosWeb.Components.AdSlot do
  @moduledoc """
  Ad slot component with pluggable ad provider support.
  """
  use Phoenix.Component

  attr :position, :string,
    required: true,
    doc: "Which ad slot to display (e.g., 'footer_center')"

  attr :provider, :atom,
    default: :none,
    doc: "Ad provider (:none, :adsense, :gam)"

  attr :ad_unit_id, :string,
    default: nil,
    doc: "Provider ad unit/slot identifier"

  attr :adsense_client_id, :string,
    default: nil,
    doc: "AdSense client id (ca-pub-...)"

  attr :gam_network_code, :string,
    default: nil,
    doc: "Google Ad Manager network code"

  @doc """
  Renders an ad slot for the selected provider.

  If missing configuration, displays a yellow placeholder.

  ## Examples

      <.ad_slot position="footer_center" />
      <.ad_slot provider={:adsense} position="footer_center" ad_unit_id="1234" adsense_client_id="ca-pub-..." />
  """
  def ad_slot(assigns) do
    min_height = get_min_height(assigns.position)
    assigns = assign(assigns, :min_height, min_height)

    ~H"""
    <div id={"ad-slot-#{@position}"} class={["ad-slot", "ad-slot-#{@position}"]} phx-update="ignore">
      <%= if @ad_unit_id do %>
        <%= case @provider do %>
          <% :adsense -> %>
            <.adsense ad_unit_id={@ad_unit_id} adsense_client_id={@adsense_client_id} />
          <% :gam -> %>
            <.gam ad_unit_id={@ad_unit_id} gam_network_code={@gam_network_code} position={@position} />
          <% _ -> %>
            <.placeholder
              position={@position}
              min_height={@min_height}
              message="Unsupported provider"
            />
        <% end %>
      <% else %>
        <.placeholder
          position={@position}
          min_height={@min_height}
          message="Missing ad_unit_id"
        />
      <% end %>
    </div>
    """
  end

  attr :ad_unit_id, :string, required: true
  attr :adsense_client_id, :string, default: nil

  defp adsense(assigns) do
    assigns = assign(assigns, :client_id, assigns.adsense_client_id)

    ~H"""
    <%= if @client_id do %>
      <script
        async
        src={"https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=#{@client_id}"}
        crossorigin="anonymous"
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
      <script phx-no-curly-interpolation>
        (adsbygoogle = window.adsbygoogle || []).push({});
      </script>
    <% else %>
      <.placeholder position="adsense" min_height={60} message="Missing adsense_client_id" />
    <% end %>
    """
  end

  attr :ad_unit_id, :string, required: true
  attr :gam_network_code, :string, default: nil
  attr :position, :string, required: true

  defp gam(assigns) do
    slot_dom_id = "gam-slot-#{assigns.position}"
    assigns = assign(assigns, :slot_dom_id, slot_dom_id)

    ~H"""
    <%= if @gam_network_code do %>
      <script async src="https://securepubads.g.doubleclick.net/tag/js/gpt.js">
      </script>
      <div id={@slot_dom_id}></div>
      <script phx-no-curly-interpolation>
        window.googletag = window.googletag || {cmd: []};
        googletag.cmd.push(function() {
          googletag
            .defineSlot('/<%= @gam_network_code %>/<%= @ad_unit_id %>', [[970, 90], [728, 90], [320, 50]], '<%= @slot_dom_id %>')
            .addService(googletag.pubads());
          googletag.enableServices();
          googletag.display('<%= @slot_dom_id %>');
        });
      </script>
    <% else %>
      <.placeholder position="gam" min_height={60} message="Missing gam_network_code" />
    <% end %>
    """
  end

  attr :position, :string, required: true
  attr :min_height, :integer, required: true
  attr :message, :string, required: true

  defp placeholder(assigns) do
    ~H"""
    <div
      style={"min-height: #{@min_height}px"}
      class="bg-yellow-100 border-2 border-yellow-400 rounded flex items-center justify-center"
    >
      <div class="text-center text-yellow-900">
        <p class="font-semibold text-sm">Ad Slot: {@position}</p>
        <p class="text-xs">{@message}</p>
      </div>
    </div>
    """
  end

  defp get_min_height("footer_center"), do: 60
  defp get_min_height(_), do: 100
end
