# ADR-02: Client Timezone-Aware Quote Retrieval

## Status

Accepted

## Context

Daily Logos displays a daily quote that should be specific to the user's local date, not the server's date/timezone.

**Problem:** A user in New York (UTC-5) at 23:00 on June 28 is still on June 28 locally, but a server in UTC might already be on June 29. The backend must know the **client's local date** at the first request (no session/cookies) to retrieve the correct quote.

**Requirements:**

- Backend must know client's local date on **first page load** (before any JS execution completes)
- Must respect client timezone, not server timezone
- No session or cookie-based state on first load
- Should work with the existing quote retrieval system
- Internationalization (Gettext) must continue to work

## Options Considered

### Option A: Query Parameter

The client sends its local date as a query parameter.

**Example:**

```elixir
# Router
get "/", PageController, :home

# Controller
def home(conn, params) do
  client_date_str = Map.get(params, "date", today_as_string())
  quote = Quotes.get_by_date(client_date_str)
  render(conn, :home, quote: quote)
end

# Template
<script :type={Phoenix.LiveView.ColocatedHook} name=".DateInitializer">
  export default {
    mounted() {
      const today = new Date();
      const dateStr = today.toISOString().split('T')[0]; // "2026-06-28"

      // Only redirect if date param is missing
      if (!new URLSearchParams(window.location.search).has('date')) {
        window.location = `/?date=${dateStr}`;
      }

      // Show date in UI
      const months = JSON.parse(this.el.dataset.months);
      const month = months[today.getMonth()];
      document.getElementById('date-display').textContent = `${month} ${today.getDate()}`;
    }
  }
</script>
```

**Flow:**

1. Browser makes request to `/`
2. Server sends page with default/fallback quote
3. JS detects no `date` param, redirects to `/?date=2026-06-28`
4. Server receives date, retrieves correct quote, returns it
5. User sees correct quote (with one extra request on first load)

**Pros:**

- ✅ Simplest to implement
- ✅ Clean, standard HTTP pattern
- ✅ Works without JavaScript (fallback to server's timezone)
- ✅ Zero additional dependencies
- ✅ Easily cacheable per-date
- ✅ No session/cookie complexity

**Cons:**

- ❌ Extra HTTP request on first page load
- ❌ Brief flicker (default quote → correct quote)
- ❌ URL shows query parameter (aesthetic concern)

**Complexity:** Low

**Trade-offs:**

- Performance: One extra request per first visit (cached after that)
- UX: Minimal flicker if redirect is fast enough
- Simplicity: Code is straightforward and maintainable

---

### Option B: AJAX Fetch After Initial Load

Server sends initial page immediately with default quote, JS fetches correct quote via AJAX.

**Example:**

```elixir
# Controller (unchanged, sends default quote first)
def home(conn, _params) do
  quote = Quotes.get_by_date(Date.utc_today())
  render(conn, :home, quote: quote)
end

# Add new route for API endpoint
get "/api/quote-for-date", QuoteApiController, :get_quote_for_date

# QuoteApiController
def get_quote_for_date(conn, params) do
  date_str = Map.get(params, "date")
  quote = Quotes.get_by_date(date_str)
  json(conn, %{text: quote.text, author: quote.author, source: quote.source})
end

# Template
<div id="quote-container" data-quote={Jason.encode!(@quote)}>
  {@quote.text}
</div>

<script :type={Phoenix.LiveView.ColocatedHook} name=".QuoteFetcher">
  export default {
    mounted() {
      const today = new Date();
      const dateStr = today.toISOString().split('T')[0];

      // Fetch correct quote immediately
      fetch(`/api/quote-for-date?date=${dateStr}`)
        .then(r => r.json())
        .then(quote => {
          document.getElementById('quote-text').textContent = quote.text;
          document.getElementById('quote-author').textContent = quote.author;
          document.getElementById('quote-source').textContent = quote.source;
        });
    }
  }
</script>
```

**Flow:**

1. Browser requests `/`
2. Server responds immediately with page + default/fallback quote
3. JS executes, detects client date, makes API call `/api/quote-for-date?date=2026-06-28`
4. Server sends correct quote as JSON
5. JS updates DOM with correct quote

**Pros:**

- ✅ No page redirect/flicker
- ✅ Parallel loading (page renders while fetch happens)
- ✅ Cleaner URL (no query params on root)
- ✅ Smooth UX if fetch is fast (<500ms)

**Cons:**

- ❌ Extra HTTP request (like Option A)
- ❌ Page shows wrong quote briefly (until fetch completes)
- ❌ Requires new API endpoint (more code)
- ❌ More complex JavaScript
- ❌ Risk of race conditions if multiple quotes update simultaneously

**Complexity:** Medium (new controller + route, more JS logic, DOM update logic)

**Trade-offs:**

- Performance: Same (one extra request) but happens in parallel
- UX: Smoother visually but shows wrong quote momentarily
- Maintainability: Extra code surface (API endpoint)

---

### Option C: LiveView Conversion (Full Real-time)

Convert the page to a LiveView and send client timezone during socket connection.

**Example:**

```elixir
# Router
live "/", QuoteLive.Index

# QuoteLive
defmodule DailyLogosWeb.QuoteLive.Index do
  use DailyLogosWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, quote: nil, loading: true)}
  end

  def handle_event("set_client_date", %{"date" => date_str}, socket) do
    quote = Quotes.get_by_date(date_str)
    {:noreply, assign(socket, quote: quote, loading: false)}
  end
end

# Template
<div id="quote-container" phx-hook=".DateNotifier">
  <%= if @loading do %>
    <p>Loading...</p>
  <% else %>
    <p>{@quote.text}</p>
  <% end %>
</div>

<script :type={Phoenix.LiveView.ColocatedHook} name=".DateNotifier">
  export default {
    mounted() {
      const today = new Date();
      const dateStr = today.toISOString().split('T')[0];

      // Send to server immediately after socket connection
      this.pushEvent("set_client_date", {date: dateStr});
    }
  }
</script>
```

**Flow:**

1. Browser requests `/`
2. LiveView HTML loads with initial blank/loading state
3. WebSocket connection established
4. JS pushes client date via WebSocket event
5. Server receives date, retrieves quote, pushes back
6. DOM updates in real-time

**Pros:**

- ✅ Real-time capability (future-proofs for live features)
- ✅ Can push updates to client without request
- ✅ No page redirect
- ✅ Elegant event-driven architecture
- ✅ State is naturally tied to socket

**Cons:**

- ❌ Requires WebSocket connection (more overhead)
- ❌ Extra complexity (LiveView setup, socket lifecycle)
- ❌ Page must load twice (HTTP + WebSocket)
- ❌ Slower initial page load than standard HTTP
- ❌ More server resource usage (persistent connections)
- ❌ Overkill for static quote page
- ❌ Session handling is more complex
- ❌ Logout/session expiry needs WebSocket management

**Complexity:** High (complete architectural shift, lifecycle management)

**Trade-offs:**

- Performance: Slower initial load, higher server memory per user
- Capability: Future real-time features become easier
- Simplicity: More moving parts to understand and debug
- Scalability: WebSocket connections are more resource-intensive than HTTP

---

### Option D: Hidden Form with JavaScript Submission (Hacky)

Submit a form with hidden date field, looks like a single request.

**Example:**

```html
<form id="date-form" method="post" action="/" style="display:none">
  <input type="hidden" name="date" id="date-input" />
  <input type="hidden" name="_csrf_token" value="{@csrf_token}" />
</form>

<script :type="{Phoenix.LiveView.ColocatedHook}" name=".AutoSubmit">
  export default {
    mounted() {
      const today = new Date();
      const dateStr = today.toISOString().split("T")[0];

      if (!new URLSearchParams(window.location.search).has("date")) {
        document.getElementById("date-input").value = dateStr;
        document.getElementById("date-form").submit();
      }
    },
  };
</script>
```

**Pros:**

- ✅ Looks like standard form submission
- ✅ Respects CSRF tokens naturally

**Cons:**

- ❌ Still requires redirect/POST
- ❌ Hacky, not semantically correct
- ❌ Confuses server logs with POST requests
- ❌ More complex than just using GET param

**Complexity:** Medium but not worth it

---

## Decision

We choose **Option B: AJAX Fetch After Initial Load** with a loading placeholder during quote fetch.

Option B is the simplest implementation path with minimal effort:

1. **Minimal Code Changes**
   - No controller modifications needed (reuse existing logic)
   - Single new route for API endpoint (`/api/quote-for-date`)
   - Straightforward JS hook for fetch + DOM update
   - No architectural changes to the app

2. **Lowest Complexity**
   - No page redirects (cleaner UX than Option A)
   - No WebSocket complexity (vs Option C)
   - No session/cookie management required
   - Standard HTTP + fetch pattern

3. **Good User Experience**
   - Placeholder + loading state shows to user that action is happening
   - Page renders immediately while fetch happens in background
   - Graceful fallback if fetch fails (shows initial quote)
   - Smooth visual flow

4. **Low Risk, Easy to Debug**
   - If something breaks, it's isolated to the API endpoint
   - Easy to test independently
   - Simple to monitor/log for production

5. **Future-Proof**
   - API endpoint reusable for other clients (mobile, etc.)
   - Easy to add caching later
   - Clean foundation if we need to expand quote system

### Trade-offs Accepted

- One extra HTTP request on first load (acceptable - parallel fetch, cached after)
- Momentary display of placeholder instead of quote (minimal UX impact, adds context)
- Slightly more code than Option A (worth it for better UX)

---

## Consequences

We will:

- Create `/api/quote-for-date` GET endpoint in controllers
- Add `Quotes.get_by_date/1` function to retrieve quote by date string
- Implement AJAX fetch hook in template with placeholder UI
- Show loading state while fetch completes
- Ensure date parameter is validated (ISO format: YYYY-MM-DD)
- Add tests for API endpoint with various dates and timezones
- Document the fetch flow for future maintainers
