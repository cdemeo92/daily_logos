defmodule DailyLogosWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use DailyLogosWeb, :html

  import DailyLogosWeb.DropdownSelect
  import DailyLogosWeb.TimezoneSelect
  import DailyLogosWeb.WeekdaySelect

  embed_templates "page_html/*"

  def feedback_form_url("it"), do: configured_url(:feedback_form_url_it)
  def feedback_form_url(_locale), do: configured_url(:feedback_form_url_en)

  defp configured_url(key) do
    case Application.get_env(:daily_logos, key) do
      url when is_binary(url) and url != "" -> url
      _ -> nil
    end
  end
end
