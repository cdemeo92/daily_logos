defmodule DailyLogosWeb.LocalePathsTest do
  use ExUnit.Case, async: true

  alias DailyLogosWeb.Components.OAuthProviders
  alias DailyLogosWeb.LocalePaths

  import Phoenix.LiveViewTest, only: [render_component: 2]

  test "leaves paths canonical for the configured default locale" do
    locale = Application.fetch_env!(:daily_logos, :i18n)[:default_locale]
    assert LocalePaths.localized_path("/auth/google", locale) == "/auth/google"
  end

  test "prefixes any nondefault locale without enumerating supported languages" do
    default = Application.fetch_env!(:daily_logos, :i18n)[:default_locale]

    for locale <- ["fr", "de", "pt-BR"], locale != default do
      assert LocalePaths.localized_path("/auth/google", locale) == "/#{locale}/auth/google"
    end
  end

  test "uses the current Gettext locale when none is supplied" do
    Gettext.with_locale(DailyLogosWeb.Gettext, "fr", fn ->
      assert LocalePaths.localized_path("/users/log-in") == "/fr/users/log-in"
    end)
  end

  test "social components support future locales without individual language branches" do
    html =
      render_component(&OAuthProviders.oauth_login_button/1,
        provider: "google",
        label: "Google",
        locale: "fr"
      )

    document = LazyHTML.from_fragment(html)

    assert LazyHTML.attribute(LazyHTML.query(document, "#oauth-login-google"), "href") == [
             "/fr/auth/google"
           ]

    html =
      render_component(&OAuthProviders.oauth_provider_settings_row/1,
        provider: "google",
        label: "Google",
        locale: "fr",
        form: Phoenix.Component.to_form(%{})
      )

    document = LazyHTML.from_fragment(html)

    assert LazyHTML.attribute(LazyHTML.query(document, "#oauth-connect-form-google"), "action") ==
             ["/fr/users/settings/identities/google"]
  end
end
