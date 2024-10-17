class ProductType < ApplicationRecord
  has_ancestry ancestry_format: :materialized_path2, orphan_strategy: :restrict
  has_many :products

  validates :name, presence: true
end
