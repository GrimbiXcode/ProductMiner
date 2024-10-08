# frozen_string_literal: true

require "./lib/product_miner/miners/migros_api"
require "sidekiq"
require "sidekiq-cron"

Sidekiq.configure_client do |config|
  config.redis = { db: 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { db: 1 }
end

# The foreman commands the miner to dig for product details
class Foreman
  include Sidekiq::Job

  def perform(miner, product_id)
    # TODO: Create DB connection

    case miner
    when "MIGROS"
      MigrosApi.new.read_product_details(product_id)
    else puts "miner #{miner} not known"
    end

    # TODO: save fetched data
  end

  def install_jobs
    puts "Uninstalling all existing jobs before recreating them again."
    Sidekiq::Cron::Job.destroy_all!
    puts "All jobs are deleted"

    puts "Installing job Migros Miner"
    migros_job = Sidekiq::Cron::Job.create(
      name: "Migros Miner - every 1min",
      cron: "* * * * *",
      class: "Foreman",
      args: ["MIGROS", "204451300000"]
    ) # execute at every 5 minutes
    raise "Job creation failed" unless migros_job

    puts "Installed jobs: #{Sidekiq::Cron::Job.all}"
  end
end

