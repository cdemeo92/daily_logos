defmodule DailyLogosWeb.Plugs.AuthRateLimitTest do
  use ExUnit.Case, async: false

  import Plug.Test

  alias DailyLogos.AuthRateLimiter
  alias DailyLogosWeb.Plugs.AuthRateLimit

  setup_all do
    start_supervised!({AuthRateLimiter, []})
    :ok
  end

  setup do
    unique = System.unique_integer([:positive])

    %{
      email: "rate-test-#{unique}@example.test",
      remote_ip: {0, 0, 0, 0, 0, 0, 1, rem(unique, 65_536)},
      opts: AuthRateLimit.init(window_ms: :timer.hours(1), email_limit: 2, ip_limit: 10)
    }
  end

  test "limits email requests and returns retry metadata", context do
    conn = request(context)

    refute AuthRateLimit.call(conn, context.opts).halted
    refute AuthRateLimit.call(conn, context.opts).halted
    blocked = AuthRateLimit.call(conn, context.opts)

    assert blocked.halted
    assert blocked.status == 429
    assert [retry_after] = Plug.Conn.get_resp_header(blocked, "retry-after")
    assert String.to_integer(retry_after) > 0
  end

  test "normalizes case and whitespace without changing request params", context do
    conn = request(context)
    normalized = %{conn | params: %{"user" => %{"email" => " #{String.upcase(context.email)} "}}}

    refute AuthRateLimit.call(normalized, context.opts).halted
    refute AuthRateLimit.call(conn, context.opts).halted
    assert AuthRateLimit.call(conn, context.opts).status == 429
    assert normalized.params["user"]["email"] == " #{String.upcase(context.email)} "
  end

  test "limits an IP even when recipients change", context do
    opts = AuthRateLimit.init(window_ms: :timer.hours(1), email_limit: 10, ip_limit: 2)

    responses =
      for index <- 1..3 do
        request(%{context | email: "#{index}-#{context.email}"}) |> AuthRateLimit.call(opts)
      end

    assert Enum.map(responses, & &1.status) == [nil, nil, 429]
  end

  test "shares the recipient quota across registration and magic links", context do
    conn = request(context)

    refute AuthRateLimit.call(%{conn | request_path: "/users/register"}, context.opts).halted
    refute AuthRateLimit.call(conn, context.opts).halted
    assert AuthRateLimit.call(conn, context.opts).status == 429
  end

  test "does not limit password or token login", context do
    conn = request(context)

    for params <- [
          %{"email" => context.email, "password" => "test-password"},
          %{"email" => context.email, "token" => "test-token"}
        ],
        _attempt <- 1..3 do
      refute AuthRateLimit.call(%{conn | params: %{"user" => params}}, context.opts).halted
    end
  end

  test "does not limit GET requests", context do
    conn = %{request(context) | method: "GET"}

    for _attempt <- 1..3 do
      refute AuthRateLimit.call(conn, context.opts).halted
    end
  end

  test "enforces recipient quotas across IPs under concurrency", context do
    responses =
      1..10
      |> Task.async_stream(fn index ->
        conn = %{request(context) | remote_ip: {127, 1, 0, index}}
        AuthRateLimit.call(conn, context.opts).status
      end)
      |> Enum.map(fn {:ok, response_status} -> response_status end)

    assert Enum.count(responses, &is_nil/1) == 2
    assert Enum.count(responses, &(&1 == 429)) == 8
  end

  defp request(context) do
    %{
      conn(:post, "/users/log-in")
      | params: %{"user" => %{"email" => context.email}},
        remote_ip: context.remote_ip
    }
  end
end
