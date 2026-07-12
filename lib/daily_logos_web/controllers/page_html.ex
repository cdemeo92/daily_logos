defmodule DailyLogosWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use DailyLogosWeb, :html

  embed_templates "page_html/*"

  def feedback_form_url("it"), do: configured_url(:feedback_form_url_it)
  def feedback_form_url(_locale), do: configured_url(:feedback_form_url_en)

  def buy_me_coffee_url do
    case Application.get_env(:daily_logos, :buy_me_coffee_url) do
      url when is_binary(url) and url != "" -> url
      _ -> nil
    end
  end

  defp configured_url(key) do
    case Application.get_env(:daily_logos, key) do
      url when is_binary(url) and url != "" -> url
      _ -> nil
    end
  end
end
