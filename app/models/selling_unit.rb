class SellingUnit < ApplicationRecord
  belongs_to :product
  belongs_to :vendor
  belongs_to :manufacturer
  belongs_to :unit
  belongs_to :currency
end
