defmodule DailyLogosWeb.ApiSpecTest do
  use ExUnit.Case, async: true

  test "documents versioned notification routes with session and CSRF security" do
    spec = DailyLogosWeb.ApiSpec.spec()
    create = spec.paths["/api/v1/notifications"].post
    update = spec.paths["/api/v1/notifications/{id}"].post
    security = [%{"sessionCookie" => [], "csrfToken" => []}]

    assert create.security == security
    assert update.security == security
    assert Map.has_key?(create.responses, 201)
    assert Map.has_key?(update.responses, 200)
    assert Map.has_key?(create.responses, 401)
    assert Map.has_key?(create.responses, 422)
    assert Map.has_key?(update.responses, 401)
    assert Map.has_key?(update.responses, 404)
    assert Map.has_key?(update.responses, 422)

    assert %{type: "apiKey", in: "cookie", name: "_daily_logos_key"} =
             spec.components.securitySchemes["sessionCookie"]

    assert %{type: "apiKey", in: "header", name: "x-csrf-token"} =
             spec.components.securitySchemes["csrfToken"]

    assert create.requestBody.required
    assert update.requestBody.required
    assert Map.has_key?(spec.components.schemas, "NotificationScheduleRequest")
    assert Map.has_key?(spec.components.schemas, "NotificationSubscriptionResponse")
    assert Map.has_key?(spec.components.schemas, "NotificationApiErrorResponse")
    assert spec.paths["/api/v1/quotes"].get.security == nil
  end
end
