# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProductMiner::Foreman do
  let(:foreman) { described_class.new }

  describe "#perform" do
    let(:product_id) { "204451300000" }
    let(:mock_data) do
      {
        "price" => { "value" => 15.99 },
        "name" => "Test Product"
      }
    end

    before do
      # Mock MigrosApi
      allow(ProductMiner::MigrosApi).to receive(:new).and_return(
        double(read_product_details: mock_data)
      )
    end

    it "creates a product and price record" do
      expect { foreman.perform("migros", product_id) }
        .to change { ProductMiner::Product.count }.by(1)
        .and change { ProductMiner::Price.count }.by(1)

      product = ProductMiner::Product.last
      expect(product.external_id).to eq(product_id)
      expect(product.store).to eq("migros")

      price = ProductMiner::Price.last
      expect(price.price).to eq(15.99)
      expect(price.product).to eq(product)
    end

    it "does not create duplicate products" do
      ProductMiner::Product.create!(external_id: product_id, store: "migros")
      
      expect { foreman.perform("migros", product_id) }
        .to change { ProductMiner::Product.count }.by(0)
        .and change { ProductMiner::Price.count }.by(1)
    end
  end
end
