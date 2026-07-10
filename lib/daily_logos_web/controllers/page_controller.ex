defmodule DailyLogosWeb.PageController do
  use DailyLogosWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def feedback(conn, _params) do
    render(conn, :feedback)
  end
end
