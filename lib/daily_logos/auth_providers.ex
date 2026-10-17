defmodule DailyLogos.AuthProviders do
  @moduledoc """
  Helpers for checking configured OAuth providers and their identity claims.
  """

  alias Ueberauth.Auth

  @oauth_modules %{
    :google => Ueberauth.Strategy.Google.OAuth,
    :github => Ueberauth.Strategy.Github.OAuth,
    :facebook => Ueberauth.Strategy.Facebook.OAuth,
    "google" => Ueberauth.Strategy.Google.OAuth,
    "github" => Ueberauth.Strategy.Github.OAuth,
    "facebook" => Ueberauth.Strategy.Facebook.OAuth
  }

  @provider_names %{"google" => :google, "github" => :github, "facebook" => :facebook}
  @provider_labels [
    {"google", "Google"},
    {"github", "GitHub"},
    {"facebook", "Facebook"}
  ]

  def available_providers do
    Enum.flat_map(@provider_labels, fn {provider, label} ->
      if configured?(provider), do: [%{id: provider, label: label}], else: []
    end)
  end

  def configured?(provider) do
    case Map.fetch(@oauth_modules, provider) do
      {:ok, module} ->
        config = Application.get_env(:ueberauth, module, [])

        Enum.all?([:client_id, :client_secret], fn key ->
          config
          |> Keyword.get(key)
          |> nonblank?()
        end)

      :error ->
        false
    end
  end

  def strategy(provider) do
    with {:ok, provider_name} <- Map.fetch(@provider_names, provider),
         {module, options} when is_list(options) <-
           Application.get_env(:ueberauth, Ueberauth, [])
           |> Keyword.get(:providers, [])
           |> Keyword.get(provider_name) do
      paths = [
        request_path: "/auth/#{provider}",
        callback_path: "/auth/#{provider}/callback"
      ]

      {:ok, {module, Keyword.merge(options, paths)}}
    else
      _ -> :error
    end
  end

  def email_verified?(%Auth{provider: :google, info: %{email: email}, extra: extra}) do
    verified_claim?(email, raw_user(extra), ["email_verified", :email_verified])
  end

  def email_verified?(%Auth{provider: :github, info: %{email: email}, extra: extra}) do
    verified_github_email?(email, raw_user(extra))
  end

  def email_verified?(%Auth{}), do: false

  def email_verified?(_auth), do: false

  defp verified_claim?(email, user, keys) do
    nonblank?(email) and Enum.any?(keys, &(Map.get(user, &1) == true))
  end

  defp verified_github_email?(email, user) do
    emails = Map.get(user, "emails", Map.get(user, :emails, []))

    nonblank?(email) and is_list(emails) and
      Enum.any?(emails, fn email_info ->
        email_info =
          if is_map(email_info) do
            email_info
          else
            %{}
          end

        email_value = Map.get(email_info, "email", Map.get(email_info, :email))
        primary? = Map.get(email_info, "primary", Map.get(email_info, :primary))
        verified? = Map.get(email_info, "verified", Map.get(email_info, :verified))

        email_value == email and primary? == true and verified? == true
      end)
  end

  defp raw_user(%{raw_info: raw_info}) when is_map(raw_info) do
    user = Map.get(raw_info, :user, Map.get(raw_info, "user", %{}))
    if is_map(user), do: user, else: %{}
  end

  defp raw_user(_extra), do: %{}

  defp nonblank?(value) when is_binary(value), do: String.trim(value) != ""
  defp nonblank?(_value), do: false
end
