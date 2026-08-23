# frozen_string_literal: true

# JSONAPI::Resources (0.10.7) is currently incompatible with Rails 8.1
# because ActionDispatch::Routing::Mapper::Resources::Resource.initialize now expects keyword arguments for only/except.
# This patch ensures that it passes keyword arguments correctly.
# Remove when https://github.com/JSONAPI-Resources/jsonapi-resources/issues/1488 is fixed

if defined?(JSONAPI)
  module ActionDispatch
    module Routing
      class Mapper
        module Resources
          class Resource
            alias_method :original_initialize, :initialize

            def initialize(entities, api_only, shallow, options = {})
              # In Rails 8.1, initialize(entities, api_only, shallow, only: nil, except: nil, **options)
              # and jsonapi-resources passes them in the options hash.
              if options.is_a?(Hash)
                only = options.delete(:only)
                except = options.delete(:except)
                original_initialize(entities, api_only, shallow, only: only, except: except, **options)
              else
                original_initialize(entities, api_only, shallow, options)
              end
            end
          end
        end
      end
    end
  end

  module JSONAPI
    module RoutingExt
      module Mapper
        def jsonapi_resource_scope(resource, resource_type)
          # The original implementation uses Resource.new which we patched above.
          # We need to make sure we don't break Rails 5/6/7/8 logic if it were to run there.
          @scope = @scope.new(scope_level_resource: resource, jsonapi_resource: resource_type)

          controller(resource.resource_scope) { yield }
        ensure
          @scope = @scope.parent
        end
      end
    end
  end
end
