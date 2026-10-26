defmodule DailyLogosWeb.Plugs.RequireAuthenticatedJsonUser do
  @moduledoc """
  Returns a JSON 401 response unless the request has an authenticated user scope.
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{assigns: %{current_scope: %{user: %{id: id}}}} = conn, _opts)
      when not is_nil(id),
      do: conn

  def call(conn, _opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: %{code: "unauthenticated"}})
    |> halt()
  end
end
