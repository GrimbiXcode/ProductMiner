# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/product_miner/foreman/foreman"

RSpec.describe Foreman do
  let(:config) { ProductMiner::Config.new }
  let(:foreman) { described_class.new(config) }

  describe "#initialize" do
    it "initializes with config" do
      expect(foreman.instance_variable_get(:@config)).to eq(config)
    end

    it "initializes with logger" do
      expect(foreman.instance_variable_get(:@logger)).to be_a(Logger)
    end
  end

  describe "#perform" do
    let(:product_id) { "204451300000" }
    let(:mock_data) do
      {
        "id" => product_id,
        "name" => "Test Product",
        "price" => { "value" => 10.99, "currency" => "CHF" }
      }
    end

    before do
      # Mock MigrosApi
      allow(MigrosApi).to receive(:new).and_return(double(read_product_details: mock_data))

      # Mock database
      mock_db = double
      mock_price_records = double(save: true)
      allow(mock_db).to receive(:price_records).and_return(mock_price_records)
      allow(mock_db).to receive(:test_connection)
      allow(ProductMiner::Database).to receive(:new).and_return(double(db: mock_db, price_records: mock_price_records))
    end

    it "fetches product data and saves it" do
      expect(MigrosApi).to receive(:new).and_return(double(read_product_details: mock_data))
      foreman.perform(:migros, product_id)
    end

    it "handles unknown miner gracefully" do
      expect { foreman.perform(:unknown, product_id) }.not_to raise_error
    end

    context "when data fetching fails" do
      before do
        allow(MigrosApi).to receive(:new).and_raise(StandardError.new("API Error"))
      end

      it "logs the error" do
        expect(foreman.instance_variable_get(:@logger)).to receive(:error).with(/Error mining/)
        expect { foreman.perform(:migros, product_id) }.to raise_error(StandardError)
      end
    end
  end

  describe "#install_jobs" do
    before do
      # Clear existing jobs
      Sidekiq::Cron::Job.destroy_all!
    end

    it "creates jobs for enabled products" do
      foreman.install_jobs
      jobs = Sidekiq::Cron::Job.all
      expect(jobs.length).to be >= 1
      expect(jobs.first.name).to include("Migros Miner")
    end

    it "uses cron schedule from config" do
      foreman.install_jobs
      jobs = Sidekiq::Cron::Job.all
      expect(jobs.first.cron).to eq("* * * * *")
    end

    it "uses correct job class" do
      foreman.install_jobs
      jobs = Sidekiq::Cron::Job.all
      expect(jobs.first.klass).to eq("Foreman")
    end
  end

  describe "private methods" do
    describe "#extract_price" do
      it "extracts price from nested hash" do
        data = { "price" => { "value" => 15.99 } }
        expect(foreman.send(:extract_price, data)).to eq(15.99)
      end

      it "extracts price from currentPrice" do
        data = { "currentPrice" => { "value" => 20.0 } }
        expect(foreman.send(:extract_price, data)).to eq(20.0)
      end

      it "returns 0.0 when no price found" do
        expect(foreman.send(:extract_price, {})).to eq(0.0)
      end
    end

    describe "#extract_product_name" do
      it "extracts name from data" do
        data = { "name" => "Test Product" }
        expect(foreman.send(:extract_product_name, data)).to eq("Test Product")
      end

      it "extracts title as fallback" do
        data = { "title" => "Test Title" }
        expect(foreman.send(:extract_product_name, data)).to eq("Test Title")
      end

      it "returns default when no name found" do
        expect(foreman.send(:extract_product_name, {})).to eq("Unknown Product")
      end
    end

    describe "#extract_currency" do
      it "extracts currency from price" do
        data = { "price" => { "currency" => "EUR" } }
        expect(foreman.send(:extract_currency, data)).to eq("EUR")
      end

      it "returns CHF as default" do
        expect(foreman.send(:extract_currency, {})).to eq("CHF")
      end
    end
  end
end
