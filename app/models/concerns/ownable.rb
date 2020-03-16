# frozen_string_literal: true

module Ownable
  extend ActiveSupport::Concern

  included do
    belongs_to :owner, class_name: 'Member',
                       foreign_key: 'owner_id', counter_cache: true

    default_scope { joins(:owner).merge(Member.kept) } # Ensures the owner still exists
  end
end
