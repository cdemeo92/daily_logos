defmodule DailyLogosWeb.Schemas.NotificationScheduleRequest do
  @moduledoc """
  OpenAPI schema for notification schedule create and update requests.
  """

  alias OpenApiSpex.Schema

  def schema do
    %Schema{
      title: "NotificationScheduleRequest",
      type: :object,
      required: [:subscription],
      properties: %{
        subscription: %Schema{
          type: :object,
          required: [:enabled],
          properties: %{
            weekdays: %Schema{
              type: :array,
              items: %Schema{type: :integer, minimum: 1, maximum: 7}
            },
            local_hour: %Schema{type: :integer, minimum: 0, maximum: 23, nullable: true},
            timezone: %Schema{type: :string, nullable: true},
            language: %Schema{type: :string, nullable: true},
            enabled: %Schema{type: :boolean}
          }
        }
      }
    }
  end
end
