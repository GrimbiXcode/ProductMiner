# frozen_string_literal: true

require "bundler/gem_tasks"
require "bundler/cli"
require "rubocop/rake_task"
require "rspec/core/rake_task"

task default: %w[lint]

RuboCop::RakeTask.new(:lint) do |task|
  task.patterns = %w[lib/**/*.rb spec/**/*.rb]
  task.fail_on_error = false
end

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = "spec/**/*_spec.rb"
  task.rspec_opts = ["--color", "--format", "documentation"]
  task.env = { "RACK_ENV" => "test" }
end

task :test => :spec

namespace :sidekiq do
  task all: %w[install run]

  task :install do
    ruby "lib/product_miner.rb"
  end

  task :run do
    exec "sidekiq -r ./lib/product_miner.rb"
  end
end

task :run do
  ruby "lib/product_miner.rb"
end

namespace :miner do
  task :migros do
    exec "irb -r ./lib/product_miner/miners/migros_api.rb"
  end

  task :test do
    exec "irb -r ./lib/product_miner/miners/test.rb"
  end
end

namespace :db do
  desc "Create database and tables"
  task :setup do
    require_relative "lib/product_miner/database"
    require_relative "lib/product_miner/config"
    
    config = ProductMiner::Config.new
    db = ProductMiner::Database.new(config)
    
    puts "Database connection established"
    puts "Tables: #{db.db.tables}"
  end

  desc "Test database connection"
  task :test do
    require_relative "lib/product_miner/database"
    require_relative "lib/product_miner/config"
    
    config = ProductMiner::Config.new
    db = ProductMiner::Database.new(config)
    
    begin
      db.test_connection
      puts "✓ Database connection successful"
    rescue => e
      puts "✗ Database connection failed: #{e.message}"
      exit 1
    end
  end
end
