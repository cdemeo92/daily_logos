defmodule DailyLogos.AccountsOAuthTest do
  use DailyLogos.DataCase

  alias DailyLogos.Accounts

  import DailyLogos.AccountsFixtures

  describe "register_oauth_user/1" do
    test "registers and confirms an account for a verified provider email" do
      attrs = oauth_identity_attrs(email: unique_user_email(), email_verified?: true)

      assert {:ok, user} = Accounts.register_oauth_user(attrs)
      assert user.email == attrs.email
      assert user.confirmed_at
      assert Accounts.get_user_by_oauth_identity(attrs.provider, attrs.provider_uid).id == user.id
    end

    test "does not create an account for an unverified provider email" do
      attrs = oauth_identity_attrs(email: unique_user_email(), email_verified?: false)

      assert {:error, :unverified_email} = Accounts.register_oauth_user(attrs)
      refute Accounts.get_user_by_email(attrs.email)
      refute Accounts.get_user_by_oauth_identity(attrs.provider, attrs.provider_uid)
    end

    test "requires an email" do
      attrs = oauth_identity_attrs(email: nil, email_verified?: true)

      assert {:error, changeset} = Accounts.register_oauth_user(attrs)
      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "rolls back the user when the provider identity is already linked" do
      attrs = oauth_identity_attrs(email: unique_user_email(), email_verified?: true)
      assert {:ok, _user} = Accounts.register_oauth_user(attrs)

      second_email = unique_user_email()
      assert {:error, _changeset} = Accounts.register_oauth_user(%{attrs | email: second_email})
      refute Accounts.get_user_by_email(second_email)
    end

    test "does not create another user for an existing email" do
      user = user_fixture()
      attrs = oauth_identity_attrs(email: user.email, email_verified?: true)

      assert {:error, changeset} = Accounts.register_oauth_user(attrs)
      assert "has already been taken" in errors_on(changeset).email
      assert Accounts.get_user_by_email(user.email).id == user.id
      refute Accounts.get_user_by_oauth_identity(attrs.provider, attrs.provider_uid)
    end
  end

  describe "link_oauth_identity/3" do
    test "links an identity to an existing account" do
      user = user_fixture()

      assert {:ok, identity} =
               Accounts.link_oauth_identity(user, "google", "google-user-1")

      assert identity.user_id == user.id
      assert Accounts.get_user_by_oauth_identity("google", "google-user-1").id == user.id
    end

    test "is idempotent when the identity is already linked to that account" do
      user = user_fixture()
      {:ok, original} = Accounts.link_oauth_identity(user, "google", "google-user-1")

      assert {:ok, ^original} =
               Accounts.link_oauth_identity(user, "google", "google-user-1")
    end

    test "does not move an identity already linked to another account" do
      original_user = user_fixture()
      other_user = user_fixture()
      {:ok, original} = Accounts.link_oauth_identity(original_user, "google", "google-user-1")

      assert {:error, :identity_already_linked} =
               Accounts.link_oauth_identity(other_user, "google", "google-user-1")

      assert Accounts.get_user_by_oauth_identity("google", "google-user-1").id == original.user_id
    end

    test "lists identities linked to a user in provider order" do
      user = user_fixture()
      {:ok, _google} = Accounts.link_oauth_identity(user, "google", "google-user-1")
      {:ok, _github} = Accounts.link_oauth_identity(user, "github", "github-user-1")

      assert Enum.map(Accounts.list_user_identities(user), & &1.provider) == ["github", "google"]
    end
  end

  defp oauth_identity_attrs(attrs) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      email_verified?: false,
      provider: "google",
      provider_uid: "google-#{System.unique_integer([:positive])}"
    })
  end
end
