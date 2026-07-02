defmodule DailyLogosWeb.PageController do
  use DailyLogosWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
