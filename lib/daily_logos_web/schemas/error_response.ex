defmodule DailyLogosWeb.Schemas.ErrorResponse do
  @moduledoc """
  OpenAPI schema for API error responses with a single detail message.
  """

  alias OpenApiSpex.Schema

  def schema do
    %Schema{
      type: :object,
      properties: %{
        errors: %Schema{
          type: :object,
          properties: %{
            detail: %Schema{type: :string}
          },
          required: [:detail]
        }
      },
      required: [:errors]
    }
  end
end
