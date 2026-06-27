# ADR-01: Internationalization Strategy

## Status

Accepted

## Context

We need English and Italian support, with automatic first-locale detection from the browser, and an explicit user switch that stays stable across requests.

## Options Considered

### Option A: Client-side i18n

Translate content in the browser using JavaScript dictionaries.

Pros:

- instant visual switch without page reload

Cons:

- extra complexity for a mostly server-rendered page
- server-generated messages (errors/flash) still need server translation or mapping
- two localization concerns to maintain over time (server rendering and client rendering)
- risk of mismatch between initial server HTML and hydrated client text

### Option B: Server-side Gettext with session locale (chosen)

Resolve locale on the server and render translations via Gettext.

Pros:

- single source of truth for translations
- native support for server-rendered pages and server-generated messages
- predictable behavior for a server-rendered quotes page

Cons:

- language switch in standard HTML requires a server roundtrip and reload
- fully live switch needs LiveView-specific handling

## Decision

Use server-side Gettext as the default internationalization mechanism.
Supported locales: en, it.

Locale resolution order:

1. user-selected locale stored in session
2. browser Accept-Language first supported value
3. fallback to en

## Locale Switch Endpoint Mechanism

Implement a browser endpoint dedicated to language switching.

Flow:

1. user clicks language switch (EN or IT)
2. request is sent to a locale endpoint in browser scope
3. endpoint validates locale against allowed values (en, it)
4. endpoint stores locale in session
5. endpoint redirects back to home (or referer)
6. on next request, Locale plug reads session locale and calls Gettext.put_locale

Result:

- user choice is persisted
- server-rendered quote page is returned in the selected language

## Consequences

- keep routing simple, no locale in URL path for now
- keep Locale plug as the single place for locale resolution
- add only minimal controller/route code for locale switching
