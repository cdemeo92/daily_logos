defmodule DailyLogosWeb.Schemas.ValidationErrorResponse do
  @moduledoc """
  OpenAPI schema for OpenApiSpex v2 validation errors.
  """

  alias OpenApiSpex.Schema

  def schema do
    %Schema{
      type: :object,
      properties: %{
        errors: %Schema{
          type: :array,
          items: %Schema{
            type: :object,
            properties: %{
              title: %Schema{type: :string},
              detail: %Schema{type: :string},
              source: %Schema{
                type: :object,
                properties: %{
                  pointer: %Schema{type: :string}
                },
                required: [:pointer]
              }
            },
            required: [:title, :detail, :source]
          }
        }
      },
      required: [:errors]
    }
  end
end
