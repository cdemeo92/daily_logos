defmodule DailyLogosWeb.OAuthController do
  use DailyLogosWeb, :controller

  alias DailyLogos.Accounts
  alias DailyLogos.Accounts.User
  alias DailyLogos.AuthProviders
  alias DailyLogosWeb.Plugs.InvalidLocalePrefix
  alias DailyLogosWeb.UserAuth
  alias Ueberauth.Auth

  plug InvalidLocalePrefix

  def request(conn, %{"provider" => provider}) do
    case current_user(conn) do
      %User{confirmed_at: confirmed_at} when not is_nil(confirmed_at) ->
        put_flash_and_redirect(
          conn,
          :info,
          gettext("Use the account settings to connect a sign-in provider."),
          settings_path(conn)
        )

      _ ->
        start_authentication(store_locale(conn), provider)
    end
  end

  def link(conn, %{"provider" => provider}) do
    case {current_user(conn), provider_strategy(provider)} do
      {%User{id: user_id, confirmed_at: confirmed_at}, {:ok, strategy}}
      when not is_nil(confirmed_at) ->
        conn
        |> store_locale()
        |> put_session(:oauth_link_user_id, user_id)
        |> Ueberauth.run_request(provider, strategy)

      {_user, :error} ->
        provider_unavailable(conn)

      _ ->
        authentication_failed(conn)
    end
  end

  def callback(conn, %{"provider" => provider}) do
    case provider_strategy(provider) do
      {:ok, strategy} ->
        conn =
          if conn.assigns[:ueberauth_auth] || conn.assigns[:ueberauth_failure] do
            conn
          else
            Ueberauth.run_callback(conn, provider, strategy)
          end

        case conn.assigns[:ueberauth_failure] do
          nil -> handle_auth(conn, provider, conn.assigns[:ueberauth_auth])
          _failure -> authentication_failed(conn)
        end

      :error ->
        provider_unavailable(conn)
    end
  end

  defp provider_strategy(provider) do
    if AuthProviders.configured?(provider) do
      AuthProviders.strategy(provider)
    else
      :error
    end
  end

  defp start_authentication(conn, provider) do
    case provider_strategy(provider) do
      {:ok, strategy} -> Ueberauth.run_request(conn, provider, strategy)
      :error -> provider_unavailable(conn)
    end
  end

  defp handle_auth(conn, provider, %Auth{} = auth) do
    with true <- provider_matches?(auth.provider, provider),
         provider_uid when is_binary(provider_uid) <- normalize_uid(auth.uid) do
      process_valid_auth(conn, auth, provider, provider_uid)
    else
      _ -> authentication_failed(conn)
    end
  end

  defp handle_auth(conn, _provider, _auth), do: authentication_failed(conn)

  defp process_valid_auth(conn, auth, provider, provider_uid) do
    case current_user(conn) do
      %User{confirmed_at: nil} -> authentication_failed(conn)
      %User{} = user -> handle_authenticated_auth(conn, user, provider, provider_uid)
      nil -> authenticate_or_register(conn, auth, provider, provider_uid)
    end
  end

  defp handle_authenticated_auth(conn, user, provider, provider_uid) do
    case get_session(conn, :oauth_link_user_id) do
      user_id when user_id == user.id ->
        link_identity(conn, user, provider, provider_uid)

      nil ->
        put_flash_and_redirect(
          conn,
          :info,
          gettext("Use the account settings to connect a sign-in provider."),
          settings_path(conn)
        )

      _other_user_id ->
        authentication_failed(conn)
    end
  end

  defp authenticate_or_register(conn, auth, provider, provider_uid) do
    case Accounts.get_user_by_oauth_identity(provider, provider_uid) do
      %User{confirmed_at: nil} ->
        put_flash_and_redirect(
          conn,
          :error,
          gettext("Confirm your email using the link we sent before signing in."),
          login_path(conn)
        )

      %User{} = user ->
        log_in_with_provider(conn, user, provider)

      nil ->
        register_provider_user(conn, auth, provider, provider_uid)
    end
  end

  defp register_provider_user(conn, auth, provider, provider_uid) do
    email = auth.info.email

    if nonblank?(email) and AuthProviders.email_verified?(auth) do
      case Accounts.register_oauth_user(%{
             email: email,
             email_verified?: true,
             provider: provider,
             provider_uid: provider_uid
           }) do
        {:ok, user} -> log_in_with_provider(conn, user, provider)
        {:error, _changeset} -> authentication_failed(conn)
      end
    else
      put_flash_and_redirect(
        conn,
        :info,
        gettext("Create and verify an account with your email before connecting this provider."),
        registration_path(conn)
      )
    end
  end

  defp link_identity(conn, user, provider, provider_uid) do
    case Accounts.link_oauth_identity(user, provider, provider_uid) do
      {:ok, _identity} ->
        conn
        |> delete_session(:oauth_link_user_id)
        |> put_session(:last_oauth_provider, provider)
        |> put_flash(:info, gettext("Sign-in provider connected."))
        |> redirect(to: settings_path(conn))

      {:error, :identity_already_linked} ->
        authentication_failed(conn)

      {:error, _changeset} ->
        authentication_failed(conn)
    end
  end

  defp log_in_with_provider(conn, user, provider) do
    conn
    |> put_session(:last_oauth_provider, provider)
    |> UserAuth.log_in_user(user)
  end

  defp provider_unavailable(conn) do
    conn
    |> delete_session(:oauth_link_user_id)
    |> put_flash_and_redirect(
      :error,
      gettext("This sign-in provider is not available."),
      fallback_path(conn)
    )
  end

  defp authentication_failed(conn) do
    conn
    |> delete_session(:oauth_link_user_id)
    |> put_flash_and_redirect(
      :error,
      gettext("We could not complete sign-in with that provider."),
      fallback_path(conn)
    )
  end

  defp put_flash_and_redirect(conn, kind, message, path) do
    conn
    |> put_flash(kind, message)
    |> redirect(to: path)
  end

  defp current_user(conn) do
    case conn.assigns[:current_scope] do
      %{user: %User{} = user} -> user
      _ -> nil
    end
  end

  defp store_locale(conn) do
    case conn.assigns[:locale] do
      locale when locale in ["en", "it"] -> put_session(conn, :locale, locale)
      _ -> conn
    end
  end

  defp provider_matches?(provider_atom, provider) when is_atom(provider_atom),
    do: Atom.to_string(provider_atom) == provider

  defp provider_matches?(provider_name, provider) when is_binary(provider_name),
    do: provider_name == provider

  defp provider_matches?(_provider_name, _provider), do: false

  defp normalize_uid(uid) when is_binary(uid) do
    uid = String.trim(uid)
    if uid == "", do: nil, else: uid
  end

  defp normalize_uid(uid) when is_integer(uid), do: Integer.to_string(uid)
  defp normalize_uid(_uid), do: nil

  defp nonblank?(value) when is_binary(value), do: String.trim(value) != ""
  defp nonblank?(_value), do: false

  defp login_path(conn), do: localized_path(conn, ~p"/users/log-in")
  defp registration_path(conn), do: localized_path(conn, ~p"/users/register")
  defp settings_path(conn), do: localized_path(conn, ~p"/users/settings")

  defp localized_path(%{assigns: %{locale: "it"}}, path), do: "/it" <> path
  defp localized_path(_conn, path), do: path

  defp fallback_path(conn) do
    case current_user(conn) do
      %User{confirmed_at: confirmed_at} when not is_nil(confirmed_at) -> settings_path(conn)
      _ -> login_path(conn)
    end
  end
end
