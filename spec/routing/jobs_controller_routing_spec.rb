# frozen_string_literal: true

require 'rails_helper'

describe JobsController do
  it 'has no page for a single job' do
    expect(get: '/jobs/water-the-beans').not_to be_routable
  end

  it 'has no page for a single job under a member' do
    expect(get: '/members/shiny/jobs/water-the-beans').not_to be_routable
  end
end
