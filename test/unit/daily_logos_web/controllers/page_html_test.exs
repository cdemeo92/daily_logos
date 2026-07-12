defmodule DailyLogosWeb.PageHTMLTest do
  use ExUnit.Case, async: false

  alias DailyLogosWeb.PageHTML

  setup do
    previous_it = Application.get_env(:daily_logos, :feedback_form_url_it)
    previous_en = Application.get_env(:daily_logos, :feedback_form_url_en)

    on_exit(fn ->
      restore_env(:feedback_form_url_it, previous_it)
      restore_env(:feedback_form_url_en, previous_en)
    end)

    :ok
  end

  test "feedback_form_url/1 returns Italian URL for it locale" do
    Application.put_env(:daily_logos, :feedback_form_url_it, "https://example.com/it")
    Application.put_env(:daily_logos, :feedback_form_url_en, "https://example.com/en")

    assert PageHTML.feedback_form_url("it") == "https://example.com/it"
  end

  test "feedback_form_url/1 returns English URL for non-it locale" do
    Application.put_env(:daily_logos, :feedback_form_url_it, "https://example.com/it")
    Application.put_env(:daily_logos, :feedback_form_url_en, "https://example.com/en")

    assert PageHTML.feedback_form_url("en") == "https://example.com/en"
    assert PageHTML.feedback_form_url(nil) == "https://example.com/en"
  end

  test "feedback_form_url/1 returns nil when selected locale URL is missing" do
    Application.put_env(:daily_logos, :feedback_form_url_it, "")
    Application.put_env(:daily_logos, :feedback_form_url_en, "https://example.com/en")

    assert PageHTML.feedback_form_url("it") == nil
  end

  defp restore_env(key, nil), do: Application.delete_env(:daily_logos, key)
  defp restore_env(key, value), do: Application.put_env(:daily_logos, key, value)
end
