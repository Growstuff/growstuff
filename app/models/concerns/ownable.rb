module Ownable
  extend ActiveSupport::Concern

  included do
    belongs_to :owner, class_name: 'Member', foreign_key: 'owner_id', counter_cache: true
  end
end
