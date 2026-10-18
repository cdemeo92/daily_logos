defmodule DailyLogosWeb.MainMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias DailyLogosWeb.Layouts.MainMenu

  test "keeps language controls in a single scroll area sized to the dynamic viewport" do
    document =
      render_component(&MainMenu.main_menu_sidebar/1, %{})
      |> LazyHTML.from_fragment()

    [classes] = document |> LazyHTML.query("#mobile-menu") |> LazyHTML.attribute("class")
    assert "h-dvh" in String.split(classes)
    refute "h-screen" in String.split(classes)
    assert "overflow-y-auto" in String.split(classes)

    assert Enum.empty?(LazyHTML.query(document, "#mobile-menu [class~='overflow-y-auto']"))
    assert Enum.count(LazyHTML.query(document, "#mobile-menu #locale-toggle-sidebar")) == 1

    assert Enum.count(
             LazyHTML.query(document, "#mobile-menu > div:last-child[class~='shrink-0']")
           ) == 1
  end
end
