# Architecture Overview

## Architectural Principles

The system is organized into clear responsibilities:

- **Core Domain**: Business rules and logic
- **Application Contexts**: Use-case orchestration
- **Web Layer**: HTTP routing, controllers, templates, and client hooks
- **Infrastructure**: Database and external integrations

This structure keeps business logic explicit and limits coupling between layers.

## System Layers

### Web Layer

**Location**: `lib/daily_logos_web/`

Entry points and presentation layer:

- **Router** (`router.ex`) - HTTP routing and request handling
- **Controllers & Templates** (`controllers/`) - Request handling and server-rendered pages
- **Colocated Hooks** (inside HEEx templates) - Client-side interactivity and API fetches
- **Components** (`components/`) - Reusable UI components

The web layer communicates with application contexts, never directly accessing infrastructure.

### Application Layer

**Location**: `lib/daily_logos/`

Business orchestration and use cases:

- **Quotes Context** (`quotes/`) - Manages quote operations (list, retrieve daily quote, etc.)
- **Users Context** (`users/`) - User management (future)
- **Subscriptions Context** (`subscriptions/`) - Subscription and notification management (future)

Each context is a module that exposes a public API. Contexts call domain logic and adapters as needed.

### Domain Layer

**Location**: `lib/daily_logos/quotes/`, `lib/daily_logos/users/`, etc.

Pure business logic with no framework dependencies:

- Domain entities (Quote, User, Subscription)
- Business rules (daily quote selection, theme organization)
- Calculations and validations
- Value objects

Domain logic should be testable without any infrastructure setup.

### Infrastructure Layer

**Location**: `lib/daily_logos/repo.ex` and throughout contexts

Concrete implementations of interfaces:

- **Ecto Repo** (`repo.ex`) - Database adapter
- **Database Schemas** - Ecto schema definitions
- External service clients (email, Slack, Telegram - future)
- Configuration management

The infrastructure layer is the only part that knows about the database, external APIs, etc.

## Project Structure

```
lib/daily_logos/
├── quotes/                   # Quote domain and context
│   ├── quote.ex              # Domain entity (Ecto schema)
│   ├── queries.ex            # Database queries (Ecto)
│   └── ...                   # Other quote-related logic
├── users/                    # User domain and context (future)
├── subscriptions/            # Subscription domain and context (future)
└── repo.ex                   # Ecto repository (database adapter)

lib/daily_logos_web/
├── components/               # Reusable UI components
│   └── core_components.ex
├── controllers/              # HTTP controllers and templates
│   ├── page_controller.ex
│   ├── quote_controller.ex
│   └── page_html/home.html.heex
├── layouts/                  # Shared layouts
├── router.ex                 # HTTP router
└── ...

test/
├── daily_logos/              # Domain & context tests
├── daily_logos_web/          # Web layer tests
├── support/                  # Test helpers & fixtures
└── ...

docs/                         # Architecture & design documentation
```

## Key Entities

### Quote

The core domain entity representing a Stoic quote.

Properties:

- `text_en` - The quote content in English
- `text_it` - The quote content in Italian
- `author` - Original Stoic thinker (Marcus Aurelius, Epictetus, Seneca, etc.)
- `day` - Day of month (1-31)
- `month` - Month (1-12)
- `topic_en` - Thematic category for the quote in English
- `topic_it` - Thematic category for the quote in Italian

## Data Flow

### Daily Quote Display (MVP)

```
User Request
    ↓
Router
    ↓
PageController (`home`)
    ↓
HEEx Template + Colocated Hook (`.DailyQuote`)
    ↓
Quote API (`/api/v1/quotes?day=...&month=...`)
    ↓
QuoteController (`show`)
    ↓
Quotes Context (`get_quote_by_day_month/2`)
    ↓
Ecto Queries
    ↓
PostgreSQL Database
    ↓
JSON response returned
    ↓
User sees daily quote
```

## Communication Between Layers

### Layer → Layer Communication Rules

1. **Web Layer → Application Context**
   - Web layer calls public functions from contexts
   - Example: `Quotes.get_quote_by_day_month(day, month)`

2. **Application Context → Domain/Infrastructure**
   - Contexts orchestrate between domain logic and adapters
   - Can call Ecto queries, perform calculations, etc.

3. **No Backwards Communication**
   - Infrastructure layer should NOT call web layer
   - Domain logic should NOT call web layer

4. **No Lateral Communication**
   - Contexts should not call other contexts directly
   - If needed, use explicit dependency injection or events (future)

## Testing Strategy

Daily Logos follows a classic **test pyramid**:

### 1. Unit Tests (largest layer)

Goal: verify most business logic quickly and deterministically.

- Focus on domain rules, calculations, validations, and pure functions
- Run without network or external services
- Should represent the majority of the test suite

Example locations:

```
test/daily_logos/quotes/...
test/daily_logos/..._test.exs
```

### 2. Integration Tests (middle layer)

Goal: verify components working together and confirm the application can build/run correctly with real adapters.

- Test context modules with Ecto + Repo
- Validate database interactions and boundaries between layers
- Fewer than unit tests, but enough to cover key integration points

Example locations:

```
test/daily_logos/quotes_test.exs
test/daily_logos/..._integration_test.exs
```

### 3. End-to-End Tests (smallest layer)

Goal: verify critical user flows that cannot be fully validated at unit level.

- Cover complete flows from entry point to rendered outcome
- Keep the set intentionally small and focused on high-value scenarios
- Avoid duplicating behavior already covered by unit/integration tests

Example locations:

```
test/integration/daily_logos_web/controllers/quote_controller_test.exs
test/daily_logos_web/e2e/...
```

## Future Considerations

As the system evolves:

1. **Background Jobs** - Will become a new adapter layer for async task processing
2. **External Integrations** - Email, Slack, Telegram will be adapters with defined ports
3. **Caching** - Can be added as an adapter without affecting domain logic
4. **Event System** - For communication between contexts (if needed)
5. **API Layer** - GraphQL or REST API will follow the same hexagonal pattern
6. **API Layer** - GraphQL or REST API can evolve using the same layered boundaries

## References

- [Elixir/Phoenix Best Practices](https://hexdocs.pm/phoenix/directory-structure.html)
