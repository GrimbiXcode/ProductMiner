# frozen_string_literal: true

require_relative "product"

module ProductMiner
  class Price < ActiveRecord::Base
    belongs_to :product
    
    validates :price, presence: true, numericality: { greater_than: 0 }
    validates :recorded_at, presence: true
  end
end
