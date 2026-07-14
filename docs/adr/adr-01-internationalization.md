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
- Unsupported or redundant prefix (e.g. `/en/about`, `/fr/about`): 302 redirect to canonical

### Locale resolution order

1. URL path prefix (`/:locale_prefix`) — takes effect immediately for that page; **does not write session**
2. Session — written only by an explicit user switch via the locale toggle
3. `Accept-Language` header — used as fallback on canonical routes when no session is set
4. Default `en`

### Locale switch mechanism

1. User clicks the locale toggle (EN or IT)
2. Hidden form POSTs to `POST /locale/:locale`
3. `LocaleController` validates the locale, writes it to session, and redirects to the localized equivalent of the referer (strips or prepends the locale prefix as needed)
4. Subsequent canonical-route requests read the session preference

### SEO signals

- `<link rel="canonical">` points to the current page URL
- `<link rel="alternate" hreflang="...">` tags are emitted for all supported locales, computed by `SeoMeta`
- `sitemap.xml` includes both canonical and Italian URL variants with `xhtml:link` alternates
- `robots.txt` disallows `/feedback` and `/it/feedback` (internal feedback form, not for public indexing)
- `robots.txt` references the full sitemap URL for production crawlers

### Navigation

All in-app navigation links use browser-native relative paths (e.g. `./about`, `./feedback`, `./`). This approach:

- Works correctly regardless of current locale prefix (`/about` stays `./about` in both `/` and `/it/` contexts)
- Requires no helper functions or locale awareness in templates
- Lets the browser handle navigation within the same locale context
- Is pragmatic: no defensive code, simple paths render simple URLs

## Consequences

- `Locale` plug is the single place for locale resolution
- `LocaleController` is the single place that writes session locale
- `SeoMeta.put_page_meta/2` is the place to override page-specific metadata (title, description, robots) for SEO control
- Adding a new locale requires: adding a Gettext locale, no other structural changes
- Pages can be explicitly excluded from indexing by setting `robots: "noindex,nofollow"` in `put_page_meta`
