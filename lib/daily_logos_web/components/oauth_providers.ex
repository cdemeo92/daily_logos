defmodule DailyLogosWeb.Components.OAuthProviders do
  @moduledoc "Reusable sign-in and account-link controls for OAuth providers."

  use Phoenix.Component
  use Gettext, backend: DailyLogosWeb.Gettext

  import DailyLogosWeb.CoreComponents, only: [button: 1]

  attr :provider, :string, required: true, values: ~w(google github facebook)
  attr :label, :string, required: true
  attr :last_used?, :boolean, default: false

  def oauth_login_button(assigns) do
    ~H"""
    <.link
      href={"/auth/#{@provider}"}
      id={"oauth-login-#{@provider}"}
      class="btn btn-outline flex min-h-12 w-full items-center justify-between gap-3"
    >
      <span class="flex items-center gap-3">
        <i class={"bi bi-#{@provider} text-lg"} aria-hidden="true"></i>
        <span>{gettext("Continue with %{provider}", provider: @label)}</span>
      </span>
      <span
        :if={@last_used?}
        id={"oauth-last-used-#{@provider}"}
        class="badge badge-soft badge-primary whitespace-nowrap"
      >
        {gettext("Last used")}
      </span>
    </.link>
    """
  end

  attr :provider, :string, required: true, values: ~w(google github facebook)
  attr :label, :string, required: true
  attr :connected?, :boolean, default: false
  attr :form, :map, required: true

  def oauth_provider_settings_row(assigns) do
    ~H"""
    <div
      id={"oauth-settings-#{@provider}"}
      class="flex flex-col gap-3 border-b border-base-300 py-4 last:border-b-0 sm:flex-row sm:items-center sm:justify-between"
    >
      <div class="flex items-center gap-3 font-medium">
        <i class={"bi bi-#{@provider} text-lg"} aria-hidden="true"></i>
        <span>{@label}</span>
      </div>
      <span :if={@connected?} class="badge badge-success badge-soft w-fit">
        {gettext("Connected")}
      </span>
      <.form
        :if={!@connected?}
        for={@form}
        id={"oauth-connect-form-#{@provider}"}
        action={"/users/settings/identities/#{@provider}"}
        method="post"
      >
        <.button class="btn btn-outline min-h-11 w-full sm:w-auto">
          {gettext("Connect %{provider}", provider: @label)}
        </.button>
      </.form>
    </div>
    """
  end
end
