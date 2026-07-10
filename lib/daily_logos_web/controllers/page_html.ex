defmodule DailyLogosWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use DailyLogosWeb, :html

  embed_templates "page_html/*"

  def feedback_form_url do
    case Application.get_env(:daily_logos, :feedback_form_url) do
      url when is_binary(url) and url != "" -> url
      _ -> nil
    end
  end
end
