defmodule DailyLogos.AuthProvidersTest do
  use ExUnit.Case, async: false

  alias DailyLogos.AuthProviders
  alias Ueberauth.Auth
  alias Ueberauth.Auth.{Extra, Info}

  @provider_modules %{
    "google" => Ueberauth.Strategy.Google.OAuth,
    "github" => Ueberauth.Strategy.Github.OAuth,
    "facebook" => Ueberauth.Strategy.Facebook.OAuth
  }

  setup do
    previous_configs =
      Map.new(@provider_modules, fn {provider, module} ->
        {provider, Application.get_env(:ueberauth, module)}
      end)

    Enum.each(@provider_modules, fn {_provider, module} ->
      Application.put_env(:ueberauth, module, [])
    end)

    on_exit(fn ->
      Enum.each(previous_configs, fn {provider, config} ->
        module = Map.fetch!(@provider_modules, provider)

        if is_nil(config) do
          Application.delete_env(:ueberauth, module)
        else
          Application.put_env(:ueberauth, module, config)
        end
      end)
    end)

    :ok
  end

  test "a provider is configured only when both credentials are nonblank" do
    refute AuthProviders.configured?("google")
    refute AuthProviders.configured?("not-a-provider")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "client-id",
      client_secret: "   "
    )

    refute AuthProviders.configured?("google")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "client-id",
      client_secret: "client-secret"
    )

    assert AuthProviders.configured?("google")
  end

  test "lists only providers with both credentials configured" do
    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "google-client",
      client_secret: "google-secret"
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Github.OAuth,
      client_id: "github-client",
      client_secret: ""
    )

    assert AuthProviders.available_providers() == [%{id: "google", label: "Google"}]
  end

  test "returns the configured strategy with a canonical callback path" do
    assert {:ok, {Ueberauth.Strategy.Google, options}} = AuthProviders.strategy("google")
    assert options[:default_scope] == "openid email"
    assert options[:request_path] == "/auth/google"
    assert options[:callback_path] == "/auth/google/callback"
    assert AuthProviders.strategy("unsupported") == :error
  end

  test "checks email verification using provider-specific raw claims" do
    google_auth = %Auth{
      provider: :google,
      info: %Info{email: "google@example.com"},
      extra: %Extra{raw_info: %{user: %{"email_verified" => true}}}
    }

    github_auth = %Auth{
      provider: :github,
      info: %Info{email: "github@example.com"},
      extra: %Extra{
        raw_info: %{
          user: %{
            "emails" => [
              %{
                "email" => "github@example.com",
                "primary" => true,
                "verified" => true
              }
            ]
          }
        }
      }
    }

    facebook_auth = %Auth{
      provider: :facebook,
      info: %Info{email: "facebook@example.com"},
      extra: %Extra{raw_info: %{user: %{"verified" => true}}}
    }

    assert AuthProviders.email_verified?(google_auth)
    assert AuthProviders.email_verified?(github_auth)
    refute AuthProviders.email_verified?(facebook_auth)
    refute AuthProviders.email_verified?(%Auth{})
  end
end
