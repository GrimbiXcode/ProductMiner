# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProductMiner::MigrosApi do
  let(:api) { described_class.new }

  describe "#authorize" do
    before do
      stub_request(:get, "https://www.migros.ch/authentication/public/v1/api/guest?authorizationNotRequired=true")
        .to_return(
          status: 200,
          headers: { leshopch: "test_header" },
          body: "{}"
        )
    end

    it "sets auth_state to :AUTHORIZED when leshopch header is present" do
      expect { api.authorize }
        .to change { api.instance_variable_get(:@auth_state) }
        .from(:UNAUTHORIZED).to(:AUTHORIZED)
    end

    it "sets leshopch_header" do
      api.authorize
      expect(api.instance_variable_get(:@leshopch_header)).to eq("test_header")
    end
  end

  describe "#read_product_details" do
    let(:product_id) { "204451300000" }
    let(:mock_response) do
      {
        "price" => { "value" => 10.95 },
        "name" => "Test Product"
      }
    end

    before do
      stub_request(:get, "https://www.migros.ch/authentication/public/v1/api/guest?authorizationNotRequired=true")
        .to_return(
          status: 200,
          headers: { leshopch: "test_header" },
          body: "{}"
        )

      stub_request(:get, "https://www.migros.ch/product-display/public/v2/product-detail")
        .with(query: { storeType: "OFFLINE", warehouseId: 2, region: "national", migrosIds: product_id })
        .to_return(
          status: 200,
          headers: {},
          body: mock_response.to_json
        )
    end

    it "returns parsed product details" do
      result = api.read_product_details(product_id)
      expect(result["price"]["value"]).to eq(10.95)
    end
  end
end
