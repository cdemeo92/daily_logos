defmodule DailyLogosWeb.CoreComponentsTest do
  use ExUnit.Case, async: true

  require Phoenix.LiveViewTest

  alias DailyLogos.Accounts.User
  alias DailyLogosWeb.CoreComponents

  test "flash notices expose a native dismiss control outside LiveView and leave the header clear" do
    html =
      Phoenix.LiveViewTest.render_component(&CoreComponents.flash/1,
        kind: :info,
        flash: %{"info" => "Account deleted"}
      )

    document = LazyHTML.from_fragment(html)
    button = LazyHTML.query(document, "#flash-info button[data-dismiss-flash]")
    assert LazyHTML.attribute(button, "data-dismiss-flash") == ["flash-info"]

    assert LazyHTML.attribute(LazyHTML.query(document, "#flash-info"), "class")
           |> Enum.any?(&String.contains?(&1, "top-20!"))
  end

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
