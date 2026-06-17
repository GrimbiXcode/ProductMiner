# frozen_string_literal: true

require "spec_helper"

RSpec.describe MigrosApi do
  let(:migros_api) { described_class.new }
  let(:base_url) { "https://www.migros.ch" }

  describe "#initialize" do
    it "initializes with default values" do
      expect(migros_api.instance_variable_get(:@user_id)).to be_nil
      expect(migros_api.instance_variable_get(:@leshopch_header)).to eq("")
      expect(migros_api.instance_variable_get(:@auth_state)).to eq(:UNAUTHORIZED)
      expect(migros_api.instance_variable_get(:@migros_url)).to eq(base_url)
    end
  end

  describe "#authorize" do
    context "when authorization is successful" do
      let(:leshopch_header) { "test-leshopch-header" }

      before do
        stub_request(:get, "#{base_url}/authentication/public/v1/api/guest?authorizationNotRequired=true")
          .to_return(
            status: 200,
            headers: { "Leshopch" => leshopch_header },
            body: "{}"
          )
      end

      it "sets the leshopch header and auth state" do
        migros_api.authorize
        expect(migros_api.instance_variable_get(:@leshopch_header)).to eq(leshopch_header)
        expect(migros_api.instance_variable_get(:@auth_state)).to eq(:AUTHORIZED)
      end
    end

    context "when authorization fails" do
      before do
        stub_request(:get, "#{base_url}/authentication/public/v1/api/guest?authorizationNotRequired=true")
          .to_return(
            status: 200,
            headers: {},
            body: "{}"
          )
      end

      it "raises an error when no leshopch header is present" do
        expect { migros_api.authorize }.to raise_error(/No authorization header was found/)
      end

      it "keeps auth state as UNAUTHORIZED" do
        expect { migros_api.authorize }.to raise_error
        expect(migros_api.instance_variable_get(:@auth_state)).to eq(:UNAUTHORIZED)
      end
    end
  end

  describe "#migros_headers" do
    let(:product_id) { "1234567890" }

    before do
      migros_api.instance_variable_set(:@leshopch_header, "test-header")
    end

    it "returns headers with leshopch and params" do
      headers = migros_api.migros_headers(product_id)
      expect(headers[:Leshopch]).to eq("test-header")
      expect(headers[:params]).to eq({
        storeType: "OFFLINE",
        warehouseId: 2,
        region: "national",
        migrosIds: product_id
      })
    end
  end

  describe "#read_product_details" do
    let(:product_id) { "204451300000" }
    let(:leshopch_header) { "test-leshopch-header" }
    let(:product_data) do
      {
        "id" => product_id,
        "name" => "Test Product",
        "price" => { "value" => 10.99, "currency" => "CHF" }
      }
    end

    before do
      # Stub authorization
      stub_request(:get, "#{base_url}/authentication/public/v1/api/guest?authorizationNotRequired=true")
        .to_return(
          status: 200,
          headers: { "Leshopch" => leshopch_header },
          body: "{}"
        )

      # Stub product details
      stub_request(:get, "#{base_url}/product-display/public/v2/product-detail")
        .with(
          headers: { "Leshopch" => leshopch_header },
          query: { storeType: "OFFLINE", warehouseId: 2, region: "national", migrosIds: product_id }
        )
        .to_return(
          status: 200,
          body: product_data.to_json
        )
    end

    it "returns parsed product details" do
      result = migros_api.read_product_details(product_id)
      expect(result).to eq(product_data)
    end

    it "authorizes if not already authorized" do
      expect(migros_api.instance_variable_get(:@auth_state)).to eq(:UNAUTHORIZED)
      migros_api.read_product_details(product_id)
      expect(migros_api.instance_variable_get(:@auth_state)).to eq(:AUTHORIZED)
    end

    context "when already authorized" do
      before do
        migros_api.instance_variable_set(:@auth_state, :AUTHORIZED)
        migros_api.instance_variable_set(:@leshopch_header, leshopch_header)
      end

      it "does not re-authorize" do
        expect(migros_api).not_to receive(:authorize)
        migros_api.read_product_details(product_id)
      end
    end
  end
end
