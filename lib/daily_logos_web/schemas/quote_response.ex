defmodule DailyLogosWeb.Schemas.QuoteResponse do
  @moduledoc """
  OpenAPI schema for quote show response payload.
  """

  alias OpenApiSpex.Schema

  def schema do
    %Schema{
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          properties: %{
            id: %Schema{type: :integer},
            day: %Schema{type: :integer},
            month: %Schema{type: :integer},
            author: %Schema{type: :string},
            source: %Schema{type: :string},
            topic_en: %Schema{type: :string},
            topic_it: %Schema{type: :string},
            text_en: %Schema{type: :string},
            text_it: %Schema{type: :string}
          }
        }
      }
    }
  end
end
