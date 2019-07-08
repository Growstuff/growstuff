class Trade < ApplicationRecord
  belongs_to :seed
  belongs_to :requested_by, class_name: 'Member', inverse_of: :trades
  delegate :owner, to: :seed
  delegate :crop, to: :seed
end
