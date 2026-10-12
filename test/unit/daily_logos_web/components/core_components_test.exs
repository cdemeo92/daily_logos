defmodule DailyLogosWeb.CoreComponentsTest do
  use ExUnit.Case, async: true

  alias DailyLogos.Accounts.User
  alias DailyLogosWeb.CoreComponents

  test "translates password confirmation errors in Italian" do
    changeset =
      User.password_changeset(
        %User{},
        %{
          "password" => "valid-test-password",
          "password_confirmation" => "different-test-password"
        },
        hash_password: false
      )

    translated =
      Gettext.with_locale(DailyLogosWeb.Gettext, "it", fn ->
        CoreComponents.translate_errors(changeset.errors, :password_confirmation)
      end)

    assert translated == ["non corrisponde alla password"]
  end

  test "translates email format errors in Italian" do
    changeset = User.email_changeset(%User{}, %{"email" => "with spaces"}, validate_unique: false)

    translated =
      Gettext.with_locale(DailyLogosWeb.Gettext, "it", fn ->
        CoreComponents.translate_errors(changeset.errors, :email)
      end)

    assert translated == ["deve contenere il simbolo @ e non deve contenere spazi"]
  end
end
