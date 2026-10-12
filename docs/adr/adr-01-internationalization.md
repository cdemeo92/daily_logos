# ADR-01: Internationalization Strategy

## Status

Accepted

## Context

We need English and Italian support, with automatic first-locale detection from the browser, an explicit user switch that stays stable across requests, and SEO-friendly URLs that expose the supported locales in the path.

## Options Considered

### Option A: Client-side i18n

Translate content in the browser using JavaScript dictionaries.

Pros:

- instant visual switch without page reload

Cons:

- extra complexity for a mostly server-rendered page
- server-generated messages (errors/flash) still need server translation or mapping
- two localization concerns to maintain (server and client)
- risk of mismatch between initial server HTML and hydrated client text

### Option B: Server-side Gettext with session only (previous)

Resolve locale on the server, store in session. No locale in URL.

Pros:

- single source of truth for translations
- simple routing

Cons:

- locale not visible in URL — search engines cannot index language-specific pages
- no hreflang signal for SEO

### Option C: Server-side Gettext with URL path prefix (chosen)

Resolve locale from the URL path prefix (`/it/...`), with session as an explicit-preference override for canonical routes.

Pros:

- locale visible and indexable in URL (`/it/about`)
- hreflang alternates can be emitted in HTML head and sitemap
- canonical (English) routes still work and fall back cleanly
- single server-side source of truth for translations

Cons:

- slightly more routing complexity
- language switch requires a server roundtrip and redirect

## Decision

Use server-side Gettext with URL path prefixes for non-default locales.
Supported locales: `en` (default), `it`.

### URL structure

- English (default): `/`, `/about`, `/support`, `/feedback`
- Italian: `/it`, `/it/about`, `/it/support`, `/it/feedback`
- Redundant default prefix (e.g. `/en/about`): 302 redirect to `/about`, preserving the query string
- Unsupported prefix on a localized route (e.g. `/fr/about`): 404, not a locale redirect
- Web actions and JSON API endpoints keep canonical URLs without a locale prefix

### Locale resolution order

1. URL path prefix (`/:locale_prefix`) — takes effect immediately for that page; **does not write session**
2. Session — written only by an explicit user switch via the locale toggle
3. `Accept-Language` header — used as fallback on canonical routes when no session is set
4. Default `en`

### Locale switch mechanism

1. User clicks the locale toggle (EN or IT)
2. The toggle sends a request to `POST /locale/:locale` with CSRF protection
3. `LocaleController` validates the locale, writes it to session, and redirects to the localized equivalent of the referer (strips or prepends the locale prefix as needed)
4. Subsequent canonical-route requests read the session preference

### SEO signals

- `<link rel="canonical">` points to the current page URL
- `<link rel="alternate" hreflang="...">` tags are emitted for all supported locales, computed by `SeoMeta`
- `sitemap.xml` includes both canonical and Italian URL variants with `xhtml:link` alternates
- `robots.txt` disallows `/feedback` and `/it/feedback` (internal feedback form, not for public indexing)
- `robots.txt` references the full sitemap URL for production crawlers

### Navigation

Use verified, root-relative paths for web navigation and form actions, for example `~p"/users/log-in"` and `~p"/users/settings"`.

- A link does not automatically insert a locale prefix. A GET to a canonical display route can subsequently be redirected by `LocaleRedirect`.
- Browser-relative paths such as `./about` depend on the current path depth and trailing slash. Do not rely on them to preserve locale on nested pages.
- Form actions stay canonical even when the page is `/it/...`. `SetLocale` resolves the action's locale from session, header, or default; it does not inherit the previous page's URL prefix.
- Visiting `/it/...` alone does not save `it` in session. With no session preference and no supported header, a canonical action uses `en`. This is intentional; do not infer locale from the referer.

### Separate resolution from redirects

- `SetLocale` resolves the locale, assigns `conn.assigns.locale`, and sets the Gettext backend locale. It never redirects or writes the session.
- `LocaleRedirect` runs after `SetLocale` and only redirects GET requests. Use it only for display routes that have a localized counterpart.
- `LocaleController` validates explicit switches and writes `:locale` to session. Session renewal during login/logout preserves only that preference while clearing authentication data as required.
- Locale-aware code called synchronously in the request process, including the email notifier, uses the same Gettext locale. Background jobs or tasks must receive the locale explicitly and apply it with `Gettext.with_locale`; process-local Gettext state is not automatically inherited.

### Procedure for new routes and APIs

Before adding an endpoint, classify its behavior rather than choosing a pipeline from its HTTP method alone:

| Endpoint type                                           | URL                                      | Pipelines                                                                      | Locale redirect                   |
| ------------------------------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------ | --------------------------------- |
| HTML display page                                       | Canonical and `/:locale_prefix` variants | `:browser`, `:locale_redirect`, `:seo`, then the appropriate auth gate         | Yes, for GET                      |
| Web action (POST/PUT/PATCH/DELETE)                      | Canonical only                           | `:browser`, appropriate auth gate; also `:seo` if an error branch renders HTML | No need to add `:locale_redirect` |
| GET that performs an action, such as email confirmation | Canonical only                           | `:browser`, appropriate auth gate                                              | No                                |
| Development dashboard or mailbox                        | Canonical `/dev/...` only                | `:browser`                                                                     | No                                |
| JSON API                                                | Canonical `/api/...` only                | `:api` and any API-specific authentication                                     | No                                |

The current `:browser` pipeline fetches the session and current scope, runs `SetLocale`, and includes flash, CSRF protection and security headers. It does not perform locale redirects or install the root layout by itself. `:seo` initializes metadata and installs the root layout that loads CSS and JavaScript.

Follow this sequence:

1. Decide whether the endpoint displays a localized page or performs an action. A GET token endpoint can perform an action without displaying a page; it must not be localized automatically merely because it is GET.
2. For a display page, declare both canonical and `/:locale_prefix` routes with equivalent authentication requirements. Include `:locale_redirect` after `:browser`; otherwise canonical links can display Italian content at an unprefixed URL without the expected redirect.
3. For a canonical action, token callback or development tool, omit `:locale_redirect`. Do not create duplicate localized routes solely to work around an unwanted redirect.
4. Include `:seo` on every HTML-rendering path, including POST/PUT validation errors and localized 404 responses. `Layouts.app` is not a substitute for the root layout. `SeoMeta.put_page_meta/2` requires initialized `:seo_meta`; omitting `:seo` can cause a 500 or a page without assets.
5. On localized display routes, handle `:invalid_locale_prefix` with the existing `InvalidLocalePrefix` plug before code accesses an authenticated user or renders the requested page. `SetLocale` marks invalid prefixes and chooses a fallback language for the 404; it does not send the 404 itself. `LocaleRedirect` leaves these requests untouched. Auth gates must preserve this 404 path rather than redirecting it to login or home.
6. Keep form action URLs and generated email/token URLs canonical. A controller may redirect to a canonical display page after processing; that subsequent GET can then be localized normally.
7. For JSON APIs, retain their explicit language contract if they have one. The current `:api` pipeline does not fetch a browser session or run `SetLocale`; do not assume it reads the locale toggle. If API localization is needed, define and validate a supported locale through an explicit API parameter/header and apply it without HTML redirects. Do not add `LocaleRedirect` to `:api` or prefix JSON endpoints with `/it` as a workaround.
8. Add the route-specific tests below before considering the endpoint complete. Keep the route declarations before catch-all routes.

For example, a protected display page has matching scopes:

```elixir
scope "/", DailyLogosWeb do
	pipe_through [:browser, :locale_redirect, :seo, :require_authenticated_user]

	get "/users/settings", UserSettingsController, :edit
end

scope "/:locale_prefix", DailyLogosWeb do
	pipe_through [:browser, :locale_redirect, :seo, :require_authenticated_user]

	get "/users/settings", UserSettingsController, :edit
end
```

Use `:require_authenticated_user` for protected controller routes so both URL variants have the same access control; use the appropriate existing gate for public or anonymous-only pages. Pass `@current_scope` to the application layout.

The corresponding action has its own canonical scope. It includes `:seo` because invalid data renders a form, but no locale redirect pipeline:

```elixir
scope "/", DailyLogosWeb do
	pipe_through [:browser, :seo, :require_authenticated_user]

	put "/users/settings", UserSettingsController, :update
end

scope "/", DailyLogosWeb do
	pipe_through [:browser, :require_authenticated_user]

	get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
end
```

The second scope processes a token and redirects; it does not render a confirmation page. Existing scopes may still include `:locale_redirect` for non-GET actions; the plug ignores those methods, but new action scopes should not depend on that incidental no-op.

Keep CSRF protection for cookie-authenticated web actions. Locale assignment does not replace authentication or CSRF checks. GET confirmation tokens are not CSRF tokens; their security depends on token validation and the required authenticated account.

### Required verification

- Canonical display route with IT session/header redirects to its defined Italian counterpart; default English remains canonical.
- Explicit `/it/...` overrides a conflicting session for that request without changing the stored preference.
- `/en/...` redirects to the canonical path and preserves query parameters; repeated slashes in a default-locale path do not produce a 500 or an external redirect.
- Unsupported prefixes return 404, including on authenticated display routes, both before and after login; no missing scope/SEO assigns or login redirect masking the error.
- Canonical actions retain the intended method and body, with no preliminary locale redirect. POST/PUT validation errors include the root layout, assets and translated messages.
- Canonical GET actions and `/dev/...` remain unprefixed with IT selected. A final redirect to a localized display page is allowed after the action completes.
- JSON APIs retain their canonical URL, media type and locale contract; browser locale preferences must not cause HTML redirects.
- Login/logout preserve the explicit session locale, while a canonical action with no session preference or supported header falls back to `en` even after a prefixed GET.
- Use `mix test.unit` for DB-free plug checks and `mix test.integ` for controller/auth flows with Testcontainers. See [the user authentication test plan](../USER_AUTH_TEST_PLAN.md) for the existing regression matrix.

Custom Ecto validation messages are dynamic Gettext keys: maintain them in `priv/gettext/errors.pot`, merge catalogs with `mix gettext.extract --merge`, and translate their Italian `errors.po` entries. Wrapping page labels alone does not translate these errors.

## Consequences

- `SetLocale` is the single place for browser request locale resolution; `LocaleRedirect` owns URL canonicalization independently
- `LocaleController` writes explicit session locale preferences; session renewal preserves the existing preference without changing it
- `SeoMeta.put_page_meta/2` is the place to override page-specific metadata (title, description, robots) for SEO control
- Adding a locale requires catalogs plus verification of prefixed routes, canonicalization, locale switch behavior and SEO alternates; it is not a catalog-only change
- Pages can be explicitly excluded from indexing by setting `robots: "noindex,nofollow"` in `put_page_meta`
