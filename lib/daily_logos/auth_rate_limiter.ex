defmodule DailyLogos.AuthRateLimiter do
  @moduledoc """
  Node-local rate limit storage for authentication email requests.
  """

  use Hammer, backend: :ets, algorithm: :fix_window_per_key
end
