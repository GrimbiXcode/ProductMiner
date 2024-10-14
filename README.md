# ProductMiner

ProductMiner is an extendable price monitoring software. Give it a place to live, feed it with API definitions, and it will record the prices of your favorite products.

## Background

This project began as my first Ruby project. Compared to other hello-world projects, I intend to make this a full-featured product.
As this is my first Ruby project, I planned the roadmap for my learning rather than for efficiency. That's why there will be a lot of refactorings to do.

## Usage

### Requirements

- Redis
  - Via Docker: `docker run --name pm-redis -p "6379:6379" -d redis redis-server --save 60 1 --loglevel warning`

### Run

## Roadmap

- [ ] First Miner (reduced features)
    - [x] Initial project setup
    - [ ] Rake configurations
    - [x] Implement Migros API (Basics)
    - [ ] Basic configurations
        - [ ] Multiple products by ID
        - [ ] Save configurations in the Postgres database
    - [x] Scheduler for monitoring tasks (Basics)
    - [ ] Record prices in a Postgres database
- [x] Website (view price chart by setting)
    - [x] Initial RoR setup
    - [ ] Simple data viewer
        - [ ] Selection with settings
        - [ ] Linechart of prices over time
    - [ ] Research and decision: pg_timeseries plugin
    - [ ] Tests
- [ ] DB relation schema, first throw
- [ ] Website and Miner improvements
    - [ ] CRUD products
    - [ ] Miner settings
- [ ] Website
    - [ ] User Registration
    - [ ] t.b.d.
- [ ] Other miners

# Miners

## Migros

API-Docs: [search-api.migros.ch](https://search-api.migros.ch/doc#)
