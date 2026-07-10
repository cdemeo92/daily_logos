defmodule DailyLogosWeb.PageController do
  use DailyLogosWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def feedback(conn, _params) do
    render(conn, :feedback)
  end

  def support(conn, _params) do
    render(conn, :support)
  end

  def about(conn, _params) do
    render(conn, :about)
  end
end
