defmodule DailyLogosWeb.QuoteController do
  use DailyLogosWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyLogos.Quotes

  action_fallback DailyLogosWeb.FallbackController

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  operation(:show,
    summary: "Get quote by day and month",
    parameters: [
      day: [
        in: :query,
        schema: %OpenApiSpex.Schema{type: :integer, minimum: 1, maximum: 31},
        required: true
      ],
      month: [
        in: :query,
        schema: %OpenApiSpex.Schema{type: :integer, minimum: 1, maximum: 12},
        required: true
      ]
    ],
    responses: [
      ok: {"Quote response", "application/json", DailyLogosWeb.Schemas.QuoteResponse},
      not_found: {"Quote not found", "application/json", DailyLogosWeb.Schemas.ErrorResponse},
      unprocessable_entity:
        {"Invalid parameters", "application/json", DailyLogosWeb.Schemas.ValidationErrorResponse}
    ]
  )

  def show(conn, %{day: day, month: month}) do
    case Quotes.get_quote_by_day_month(day, month) do
      nil ->
        {:error, :not_found, "Quote not found"}

      quote ->
        render(conn, :show, quote: quote)
    end
  end
end
