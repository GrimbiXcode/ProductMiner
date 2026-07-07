# frozen_string_literal: true

require_relative "db"

module ProductMiner
  class Product < ActiveRecord::Base
    has_many :prices, dependent: :destroy
    
    validates :external_id, presence: true, uniqueness: { scope: :store }
    validates :store, presence: true
  end
end
