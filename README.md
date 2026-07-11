# Daily Logos

## What is Daily Logos?

Daily Logos is a SaaS platform that delivers carefully curated Stoic philosophy quotes daily. Each day of the year corresponds to a specific quote from the great Stoic thinkers, organized by monthly themes. Inspired by the structure of _The Daily Stoic_ but with a distinct voice, Daily Logos provides a moment of philosophical reflection and practical wisdom for modern life.

Users receive a daily quote aligned with their day of the year, creating a complete cycle of Stoic wisdom across all 365 days.

## Tech Stack

- **Framework**: Phoenix 1.8
- **Language**: Elixir
- **Database**: PostgreSQL (via Ecto)
- **Frontend**: HEEx templates + Tailwind CSS v4
- **Testing**: ExUnit + Phoenix.LiveViewTest

## Getting Started

### Prerequisites

- Elixir 1.17+
- Erlang/OTP 27+
- Docker (Docker Desktop/Rancher Desktop) with `docker` and `docker compose` available
- PostgreSQL 18+ (or run the provided Docker Compose service)
- Node.js 24+ (for asset building)

### Local Development Setup

The development database is configured at runtime via `DATABASE_URL`, matching the production setup pattern.

1. **Copy environment variables**

   ```bash
   cp .env.example .env
   ```

2. **Start PostgreSQL with Docker**

   ```bash
   docker compose up -d
   ```

3. **Install dependencies and setup database**

   ```bash
   mix setup
   ```

4. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```

The app will be available at `http://localhost:4000`

### Dev Container Setup

If you want to develop without installing Elixir/Erlang/Node locally, use the provided [Dev Container](https://containers.dev/).

1. Open the repository in VS Code
2. Run `Dev Containers: Reopen in Container`
3. Wait for the post-create steps (`mix deps.get`, `mix ecto.setup`, `mix assets.setup`)
4. Start Phoenix inside the container:

   ```bash
   mix phx.server
   ```

Inside the container, `DATABASE_URL` points to `db:5432` automatically.

### Running Tests

```bash
# Run all tests
mix test

# Run integration tests (requires Docker running for testcontainers)
mix test.integ

# Run unit tests only
mix test.unit

# Run unit + integration aliases
mix test.all

# Run a specific test file
mix test test/daily_logos_web/live/home_live_test.exs

# Run failed tests only
mix test --failed
```

### Seeding Data

```bash
# Seed quotes from CSV (priv/repo/seeds/quotes.csv)
mix seed
```

### Code Quality

```bash
# Run local pre-commit checks
mix precommit

# Run Dialyzer locally when needed
MIX_ENV=dev mix dialyzer
```

The repository includes a versioned Git hook at `githooks/pre-commit`. Enable it once per clone:

```bash
git config core.hooksPath githooks
```

## Developer Workflow

### Local Quality Gates

- `mix precommit` runs compilation with warnings as errors, formatting checks, and Credo.
- `MIX_ENV=dev mix dialyzer` is intentionally kept outside the Git pre-commit hook because it is slower and better suited for CI or explicit local runs.

### Environment Loading

- In development, `.env` is loaded automatically through Dotenvy.
- In test, configuration comes from `config/test.exs` and optional overrides such as `TEST_DATABASE_URL`.
- In production, runtime configuration still relies on real system environment variables.

## Project Structure

The project follows **Hexagonal Architecture** with **Screaming Architecture** principles. The code organization reflects the business domain rather than technical layers.

### Main Directories

```
lib/
├── daily_logos/              # Domain & application contexts
│   ├── quotes/               # Quote domain logic
│   └── repo.ex               # Database adapter
├── daily_logos_web/          # Web layer (ports & adapters)
│   ├── live/                 # LiveView pages
│   ├── components/           # Reusable components
│   └── router.ex             # HTTP routing
config/                       # Configuration files
test/                         # Test suite
docs/                         # Architecture & design documents
```

For a detailed explanation of the architectural approach, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Documentation

- **[Architecture Overview](docs/ARCHITECTURE.md)** - System design, layers, and principles
- **[Roadmap](docs/ROADMAP.md)** - Project phases and feature planning

## Contributing

This project prioritizes code clarity, maintainability, and adherence to Elixir/Phoenix best practices. Before submitting changes, ensure:

1. All tests pass: `mix test`
2. Code quality checks pass: `mix precommit`

---

**Built with Elixir & Phoenix** | Stoic Wisdom for Every Day

If you later run Phoenix inside Docker as well, change the host in `DATABASE_URL` from `localhost` to the Compose service name (`db`).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
