class Product < ApplicationRecord
  belongs_to :product_type

  validates :name, presence: true
  validates :product_type_id, presence: true
end
