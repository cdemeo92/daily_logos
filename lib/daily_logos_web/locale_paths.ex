defmodule DailyLogosWeb.LocalePaths do
  @moduledoc "Builds localized paths using the configured default and the current request locale."

  @default_locale Application.compile_env(:daily_logos, :i18n)[:default_locale]

  def localized_path(path, locale \\ nil) do
    locale = locale || Gettext.get_locale(DailyLogosWeb.Gettext)

    if locale == @default_locale do
      path
    else
      "/#{URI.encode(locale, &URI.char_unreserved?/1)}#{path}"
    end
  end
end
