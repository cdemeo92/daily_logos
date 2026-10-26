# Roadmap & MVP

## Project Vision

Daily Logos aims to become a comprehensive Stoic wisdom platform that meets users where they are—delivering daily inspiration through their preferred channels and enabling deeper exploration of Stoic philosophy.

## MVP - Phase 1: Daily Quote Platform

**Goal**: Core product delivering daily Stoic quotes with a complete yearly cycle.

### Features

- [x] **Quote Repository**
  - [x] 365 daily quotes (one per day of year)
  - [x] Organized by monthly themes
  - [x] Sourced from major Stoic thinkers (Marcus Aurelius, Epictetus, Seneca, etc.)

- [x] **Home Page**
  - [x] Display only today's Stoic quote
  - [x] Show quote author and month theme
  - [x] Maintain a clean, minimalist UI aligned with Stoic philosophy

- [x] **Responsive Design**
  - [x] Mobile-friendly interface
  - [x] Works across all devices

### Technical Requirements

- [x] Database schema for quotes with `day_of_year` and monthly themes
- [x] Quotes context with query logic for daily quote retrieval
- [x] Home page implementation (LiveView or Controller-based, no real-time requirement)
- [x] Test coverage for core functionality
- [x] Clean architecture alignment (hexagonal pattern)

---

## Phase 2: User Authentication

**Goal**: Enable users to create accounts and manage their notification preferences.

### Features

- [x] User registration and authentication
- [x] User profiles with preferences
- [x] Email address management for future notifications

### Technical Requirements

- [x] User schema and authentication system
- [x] Session management
- [x] User context
- [x] Password hashing and security best practices

### Timeline

After MVP completion.

---

## Phase 3: Email Notifications

**Goal**: Deliver daily quotes to a user's verified email on their chosen schedule.

### Destination

- [ ] 📧 **Email** - Daily digest via email

### Features

- [x] Schedule delivery time based on user timezone
- [x] Toggle email notifications on/off
- [x] Select delivery weekdays and language

### Technical Requirements

- [ ] Background job system with Oban Cron and an email worker
- [ ] Email delivery through the existing mailer
- [ ] Notification scheduler and best-effort retry/expiry handling
- [x] Timezone support

### Timeline

After Phase 2.

---

## Current Status

**Active**: MVP (Phase 2)

_Last Updated: 2026-09-24_
