# frozen_string_literal: true

class BaseResource < JSONAPI::Resource
  abstract

  [:create, :update, :remove].each do |action|
    set_callback action, :before, :authorize
  end

  # Check authorisation for write operations.
  # NOTE: At a later time, we may require API tokens for READ operations.
  def authorize
    # context[:action] is simply context[:controller].params[:action]
    context[:current_ability].authorize! context[:action].to_sym, @model
  end
end
