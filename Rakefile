# frozen_string_literal: true

require "bundler/gem_tasks"
require "bundler/cli"
require "rubocop/rake_task"
require "rspec/core/rake_task"

task default: %w[lint]
# task default: %w[lint test]

RuboCop::RakeTask.new(:lint) do |task|
  task.patterns = %w[lib/**/*.rb test/**/*.rb]
  task.fail_on_error = false
end

task default: :spec

namespace :sidekiq do
  task all: %w[install run]

  task :install do
    ruby "lib/product_miner.rb"
  end

  task :run do
    exec "sidekiq -r ./lib/product_miner/foreman/foreman.rb"
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
