# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

ProductMiner is an extendable price monitoring software built as a Ruby on Rails application with background job processing. It fetches product data from various APIs (currently Migros) and stores pricing information over time for analysis.

## Architecture

### Core Components

**Rails Web Application**: The main web interface built with Rails 7.2, using Tailwind CSS for styling and Turbo/Stimulus for modern frontend interactions.

**Background Job System**: Uses Sidekiq with Redis for processing price mining jobs. The `Foreman` class schedules and manages mining tasks that run periodically.

**Price Mining Engine**: Located in `lib/product_miner/`, contains API miners (currently `MigrosApi`) that fetch product data from external sources.

**Database Design**: PostgreSQL with a hierarchical product structure using the Ancestry gem for product categories. The schema supports:
- Products with hierarchical product types
- Selling units linking products to vendors/manufacturers
- Time-series selling data for price tracking
- Countries, currencies, units, and vendor information

### Key Architectural Patterns

- **Hybrid Application**: Combines a standard Rails web app (`app/`) with a gem-like structure (`lib/product_miner/`)
- **Job Processing**: Uses Sidekiq for async processing with scheduled cron jobs
- **Hierarchical Data**: Product types use materialized path for efficient tree queries
- **Time Series Data**: Selling data records prices over time with timestamps

## Development Commands

### Setup & Database
```bash
# Install dependencies
bundle install

# Set up database (requires PG_PASSWORD environment variable)
export PG_PASSWORD=<your-password>
bin/rails db:reset     # Drop and recreate database
bin/rails db:migrate   # Run pending migrations
bin/rails db:seed      # Load seed data
```

### Development Server
```bash
# Start development server with CSS watching
bin/dev                # Runs both Rails server and Tailwind CSS watcher

# Manual alternatives
bin/rails server       # Web server only
bin/rails tailwindcss:watch  # CSS file watcher only
```

### Testing & Quality
```bash
# Run full test suite
bin/rails test test:system

# Run specific tests
bin/rails test test/models/product_test.rb
bin/rails test:system test/system/admin_test.rb

# Security scanning
bin/brakeman --no-pager

# Linting
bin/rubocop -f github
bin/rubocop -a         # Auto-fix issues

# JavaScript dependency audit
bin/importmap audit
```

### Background Jobs & Mining
```bash
# Start Sidekiq for background job processing
bundle exec sidekiq

# Access Sidekiq web UI (add to routes if needed)
# Visit /sidekiq for job monitoring

# Console testing of miners
bin/rails console
> MigrosApi.new.read_product_details("204451300000")
> ProductMiner::ProductMiner.new  # Initialize and install jobs
```

### Database Operations
```bash
# Database console
bin/rails dbconsole

# Generate new migrations
bin/rails generate migration AddFieldToProduct field:string

# Check migration status
bin/rails db:migrate:status

# Reset test database
bin/rails db:test:prepare
```

## External Dependencies

### Required Services
- **Redis**: Used by Sidekiq for job queuing (default: localhost:6379, db:1)
- **PostgreSQL**: Main database with user `product_miner` and database `product_miner_development`

### Docker Setup for Redis
```bash
docker run --name pm-redis -p "6379:6379" -d redis redis-server --save 60 1 --loglevel warning
```

## Key Files & Directories

### Application Structure
- `app/models/`: Rails models with product hierarchy and selling data
- `app/controllers/`: Web controllers including admin interface
- `lib/product_miner/`: Core mining engine and job management
- `lib/product_miner/miners/`: API-specific miners (MigrosApi)
- `lib/product_miner/foreman/`: Job scheduling and management

### Configuration
- `config/database.yml`: Database configuration
- `Procfile.dev`: Development process definitions
- `bin/dev`: Development server startup script
- `.github/workflows/ci.yml`: CI pipeline with tests, linting, security scans

### Important Model Relationships
- `ProductType`: Hierarchical categories using Ancestry gem
- `Product`: Core product entity linked to product types
- `SellingUnit`: Links products to vendors/manufacturers with units/currency
- `SellingData`: Time-series price data linked to selling units

## Development Notes

This is the author's first Ruby project with a focus on learning over efficiency. Expect ongoing refactoring as the codebase matures.

The project combines traditional Rails patterns with a custom gem-like mining engine. When working with the mining functionality, focus on the `lib/product_miner/` directory structure.

The database schema includes a diagram at `docs/diagrams/db_schema.png` for visual reference of the data model relationships.
