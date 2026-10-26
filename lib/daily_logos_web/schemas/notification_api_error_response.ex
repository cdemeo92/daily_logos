defmodule DailyLogosWeb.Schemas.NotificationApiErrorResponse do
  @moduledoc """
  OpenAPI schema for notification API errors.
  """

  alias OpenApiSpex.Schema

  def schema do
    %Schema{
      title: "NotificationApiErrorResponse",
      type: :object,
      required: [:error],
      properties: %{
        error: %Schema{
          type: :object,
          required: [:code],
          properties: %{
            code: %Schema{
              type: :string,
              enum: ["unauthenticated", "not_found", "validation_failed"]
            },
            message: %Schema{type: :string},
            fields: %Schema{
              type: :object,
              additionalProperties: %Schema{
                type: :array,
                items: %Schema{type: :string}
              }
            }
          }
        }
      }
    }
  end
end
