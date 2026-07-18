defmodule DailyLogosWeb.ErrorController do
  use DailyLogosWeb, :controller

  action_fallback DailyLogosWeb.FallbackController

  def error(_conn, _param) do
    {:error, :not_found}
  end
end
