# frozen_string_literal: true

require_relative "../miners/migros_api"
require_relative "../config"
require_relative "../database"
require "sidekiq"
require "sidekiq-cron"
require "json"
require "logger"

# The foreman commands the miner to dig for product details
class Foreman
  include Sidekiq::Job

  def initialize(config = nil)
    @config = config || ProductMiner::Config.new
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO
    @db = nil
  end

  def perform(miner, product_id)
    setup_redis
    setup_database

    @logger.info("Starting mining job for #{miner}:#{product_id}")

    begin
      data = fetch_product_data(miner, product_id)
      save_price_record(miner, product_id, data)
      @logger.info("Successfully mined and stored data for #{product_id}")
    rescue StandardError => e
      @logger.error("Error mining #{miner}:#{product_id}: #{e.message}")
      raise e
    end
  end

  def install_jobs
    setup_redis
    @logger.info("Uninstalling all existing jobs before recreating them again.")
    Sidekiq::Cron::Job.destroy_all!
    @logger.info("All jobs are deleted")

    scheduler_config = @config.scheduler_config
    products = @config.enabled_products

    products.each do |product|
      miner = product["miner"] || "migros"
      product_id = product["id"]
      cron = scheduler_config.dig(miner, "cron") || "* * * * *"

      next unless scheduler_config.dig(miner, "enabled") != false

      job_name = "#{miner.capitalize} Miner - #{product_id}"
      @logger.info("Installing job: #{job_name} with cron: #{cron}")

      job = Sidekiq::Cron::Job.create(
        name: job_name,
        cron: cron,
        class: "Foreman",
        args: [miner.upcase, product_id]
      )
      raise "Job creation failed for #{job_name}" unless job
    end

    @logger.info("Installed jobs: #{Sidekiq::Cron::Job.all.map(&:name).join(', ')}")
  end

  private

  def setup_redis
    redis_config = @config.redis_config
    redis_url = "redis://#{redis_config['host']}:#{redis_config['port']}/#{redis_config['db']}"

    Sidekiq.configure_client do |config|
      config.redis = { url: redis_url }
    end

    Sidekiq.configure_server do |config|
      config.redis = { url: redis_url }
    end
  rescue StandardError => e
    @logger.warn("Redis connection failed: #{e.message}")
    # In test mode, Sidekiq::Testing.fake! is used, so this is okay
    raise e unless ENV["RACK_ENV"] == "test" || defined?(Sidekiq::Testing)
  end

  def setup_database
    return @db if @db

    @db = ProductMiner::Database.new(@config)
    @db.test_connection
    @db
  end

  def fetch_product_data(miner, product_id)
    case miner.to_s.upcase
    when "MIGROS"
      MigrosApi.new.read_product_details(product_id)
    else
      @logger.warn("Miner #{miner} not known")
      {}
    end
  end

  def save_price_record(miner, product_id, data)
    return unless data && !data.empty?

    price = extract_price(data)
    product_name = extract_product_name(data)

    record = {
      product_id: product_id,
      product_name: product_name,
      miner: miner.to_s.downcase,
      price: price,
      original_price: extract_original_price(data),
      currency: extract_currency(data),
      product_data: data.to_json,
      recorded_at: Time.now.utc
    }

    @db.price_records.save(record)
  end

  def extract_price(data)
    # Try to extract price from Migros API response
    data.dig("price", "value") || data.dig("currentPrice", "value") || 0.0
  end

  def extract_original_price(data)
    data.dig("price", "originalValue") || data.dig("originalPrice", "value")
  end

  def extract_currency(data)
    data.dig("price", "currency") || "CHF"
  end

  def extract_product_name(data)
    data.dig("name") || data.dig("title") || "Unknown Product"
  end
end

