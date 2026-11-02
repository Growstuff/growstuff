# frozen_string_literal: true

# Controllers for something still being rolled out: not found until an admin
# switches the feature on.
module FeatureGated
  extend ActiveSupport::Concern

  class_methods do
    def require_feature(name)
      before_action { raise ActiveRecord::RecordNotFound unless Feature.enabled?(name) }
    end
  end
end
