defmodule DailyLogosWeb.Schemas.NotificationSubscriptionResponse do
  @moduledoc """
  OpenAPI schema for a saved notification subscription response.
  """

  alias OpenApiSpex.Schema

  def schema do
    %Schema{
      title: "NotificationSubscriptionResponse",
      type: :object,
      required: [:data, :message],
      properties: %{
        data: %Schema{
          type: :object,
          required: [:id, :provider, :enabled],
          properties: %{
            id: %Schema{type: :integer},
            provider: %Schema{type: :string, enum: ["email"]},
            weekdays: %Schema{
              type: :array,
              items: %Schema{type: :integer, minimum: 1, maximum: 7},
              nullable: true
            },
            local_hour: %Schema{type: :integer, minimum: 0, maximum: 23, nullable: true},
            timezone: %Schema{type: :string, nullable: true},
            language: %Schema{type: :string, nullable: true},
            enabled: %Schema{type: :boolean}
          }
        },
        message: %Schema{type: :string}
      }
    }
  end
end
