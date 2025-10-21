class Country < ApplicationRecord
  belongs_to :currency, optional: true
end
