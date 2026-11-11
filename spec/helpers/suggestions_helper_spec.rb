# frozen_string_literal: true

require 'rails_helper'

describe SuggestionsHelper do
  def methods_of(helper)
    helper.instance_methods(false) + helper.private_instance_methods(false)
  end

  # Every helper is mixed into every view, so a method here with the name of one in another helper replaces it on all pages.
  it 'has no method with the name of one in another helper' do
    helpers = Rails.root.glob('app/helpers/**/*.rb').filter_map do |path|
      path.to_s.delete_prefix(Rails.root.join('app/helpers/').to_s).delete_suffix('.rb').camelize.safe_constantize
    end
    others = (helpers - [described_class]).flat_map { |helper| methods_of(helper) }
    expect(methods_of(described_class) & others).to be_empty
  end
end
