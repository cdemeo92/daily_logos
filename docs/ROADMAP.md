# Roadmap & MVP

## Project Vision

Daily Logos aims to become a comprehensive Stoic wisdom platform that meets users where they are—delivering daily inspiration through their preferred channels and enabling deeper exploration of Stoic philosophy.

## MVP - Phase 1: Daily Quote Platform

**Goal**: Core product delivering daily Stoic quotes with a complete yearly cycle.

### Features

- [ ] **Quote Repository**
  - [ ] 365 daily quotes (one per day of year)
  - [ ] Organized by monthly themes
  - [ ] Sourced from major Stoic thinkers (Marcus Aurelius, Epictetus, Seneca, etc.)

- [ ] **Home Page**
  - [ ] Display only today's Stoic quote
  - [ ] Show quote author and month theme
  - [ ] Maintain a clean, minimalist UI aligned with Stoic philosophy

- [ ] **Responsive Design**
  - [ ] Mobile-friendly interface
  - [ ] Works across all devices

### Technical Requirements

- [ ] Database schema for quotes with `day_of_year` and monthly themes
- [ ] Quotes context with query logic for daily quote retrieval
- [ ] Home page implementation (LiveView or Controller-based, no real-time requirement)
- [ ] Test coverage for core functionality
- [ ] Clean architecture alignment (hexagonal pattern)

---

## Phase 2: User Authentication & Subscriptions

**Goal**: Enable users to create accounts and manage their notification preferences.

### Features

- [ ] User registration and authentication
- [ ] User profiles with preferences
- [ ] Subscription plans (Free tier included)
- [ ] Email address management for future notifications

### Technical Requirements

- [ ] User schema and authentication system
- [ ] Session management
- [ ] User context
- [ ] Password hashing and security best practices

### Timeline

After MVP completion.

---

## Phase 3: Multi-Channel Notifications

**Goal**: Deliver daily quotes through user's preferred communication channels.

### Channels

- [ ] 📧 **Email** - Daily digest via email
- [ ] 💬 **Slack** - Daily quote in Slack workspace
- [ ] 🤖 **Telegram** - Daily quote via Telegram bot
- [ ] 🔔 **In-App Notifications** - Browser notifications (future)

### Features

- [ ] Schedule delivery time based on user timezone
- [ ] Toggle notifications on/off per channel
- [ ] Delivery frequency settings (daily, weekly, monthly)

### Technical Requirements

- [ ] Background job system (likely using Oban)
- [ ] External service integrations (email, Slack, Telegram APIs)
- [ ] Notification scheduler
- [ ] Delivery status tracking and retry logic
- [ ] Timezone support

### Timeline

After Phase 2.

---

## Phase 4: Community & Content

**Goal**: Expand platform with community features and user-generated content.

### Features (Planned)

- [ ] User-submitted quotes and reflections
- [ ] Community commentary on daily quotes
- [ ] Curated collections and themes
- [ ] Social sharing capabilities

### Timeline

Subject to user demand and community feedback.

---

## Current Status

**Active**: MVP (Phase 1)

Start here if you're new to the project:

1. Read [docs/ARCHITECTURE.md](ARCHITECTURE.md) to understand the system design
2. Examine the Quote schema and seed data
3. Review the home page implementation
4. Run tests to verify everything works: `mix test`

## How to Contribute

At each phase, we prioritize:

1. **Code Quality** - Readability, maintainability, test coverage
2. **Architectural Clarity** - Following hexagonal architecture principles
3. **User Experience** - Clean, intuitive interfaces
4. **Documentation** - Clear code and architectural docs

See [README.md](../README.md) for contribution guidelines and setup instructions.

---

## Success Metrics (Future)

- ✨ Daily active users
- 📊 Quote delivery success rate
- 💬 Community engagement
- 🎯 User retention

_Last Updated: 2026-06-24_
