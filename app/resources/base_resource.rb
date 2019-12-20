# frozen_string_literal: true

class BaseResource < JSONAPI::Resource
  immutable
  abstract
end
