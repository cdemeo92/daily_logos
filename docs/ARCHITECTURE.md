# Architecture Overview

## Architectural Principles

Daily Logos follows two core architectural patterns:

### 1. Hexagonal Architecture (Ports & Adapters)

The system is organized into clear layers that insulate the core business logic from external dependencies:

- **Core Domain**: Business rules and logic (independent of framework/database)
- **Application Contexts**: Orchestration of domain logic with adapters
- **Ports**: Interfaces that define how the system interacts with the outside world
- **Adapters**: Concrete implementations of ports (database, web, external services)

This approach allows the core business logic to be tested and modified independently of infrastructure concerns.

### 2. Screaming Architecture

The project structure **screams** the business domain:

- Folders are organized around **what the app does** (quotes, users, subscriptions)
- Not around **technical layers** (models, views, controllers)
- A new developer reading the structure immediately understands the business intent

## System Layers

### Web Layer

**Location**: `lib/daily_logos_web/`

Entry points and presentation layer:

- **Router** (`router.ex`) - HTTP routing and request handling
- **LiveViews** (`live/`) - Real-time interactive pages
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
├── live/
│   ├── home_live.ex          # Home page LiveView
│   ├── home_live.html.heex   # Home template
│   └── ...
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

- `text` - The quote content
- `author` - Original Stoic thinker (Marcus Aurelius, Epictetus, Seneca, etc.)
- `day_of_year` - Corresponds to a specific day (1-365)
- `month_theme` - Thematic category for the month

## Data Flow

### Daily Quote Display (MVP)

```
User Request
    ↓
Router
    ↓
Home LiveView
    ↓
Quotes Context (get_daily_quote/1)
    ↓
Ecto Queries
    ↓
PostgreSQL Database
    ↓
Quote returned & rendered
    ↓
HEEx Template
    ↓
User sees daily quote
```

## Communication Between Layers

### Layer → Layer Communication Rules

1. **Web Layer → Application Context**
   - Web layer calls public functions from contexts
   - Example: `Quotes.get_daily_quote()`

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
test/daily_logos_web/live/home_live_test.exs
test/daily_logos_web/e2e/...
```

## Future Considerations

As the system evolves:

1. **Background Jobs** - Will become a new adapter layer for async task processing
2. **External Integrations** - Email, Slack, Telegram will be adapters with defined ports
3. **Caching** - Can be added as an adapter without affecting domain logic
4. **Event System** - For communication between contexts (if needed)
5. **API Layer** - GraphQL or REST API will follow the same hexagonal pattern

## References

- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
- [Screaming Architecture](https://blog.cleancoder.com/uncle-bob/2011/09/30/Screaming-Architecture.html)
- [Elixir/Phoenix Best Practices](https://hexdocs.pm/phoenix/directory-structure.html)
