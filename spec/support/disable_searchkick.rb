RSpec.configure do |config|
  config.before(:suite) do
    Searchkick.disable_callbacks
  end
end

# Stub Searchkick globally to avoid connection errors in tests
module Searchkick
  def self.server_bootstrap; end

  class Index
    def reindex(*args)
      true
    end
    def refresh
      true
    end
  end
end

# Make sure all models have search and reindex stubbed
module SearchStub
  extend ActiveSupport::Concern
  included do
    def self.search(*args, **kwargs)
      # Searchkick returns a Searchkick::Results object.
      # Many tests call .first or .count or .map on it.
      []
    end
    def reindex(*args)
      true
    end
    def self.reindex(*args)
      true
    end
  end
end

# Patch Searchkick module itself because some models call Searchkick.search
module Searchkick
  def self.search(*args, **kwargs)
    []
  end
end

ActiveSupport.on_load(:active_record) do
  include SearchStub
end

# Specific stub for Planting.homepage_records which uses Searchkick
# We want it to return some records so the tests pass if they depend on it
ActiveSupport.on_load(:active_record) do
  if self == Planting
    def self.homepage_records(limit)
       all.limit(limit)
    end
  end
end
