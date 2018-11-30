require 'rails_helper'

RSpec.describe ContainersController, type: :controller do
  include Devise::Test::ControllerHelpers
  let(:valid_params) { { description: 'My second Container' } }

  let(:container) { FactoryBot.create :container }

  let(:member) { FactoryBot.create(:member) }
  let(:admin_member) { FactoryBot.create(:admin) }
end
