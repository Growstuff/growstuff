# frozen_string_literal: true

require 'rails_helper'

describe "garden_types/show" do
  subject { render }

  let!(:garden_type) { FactoryBot.create(:garden_type, name: "Hot Sauce") }

  before do
    controller.stub(:current_user) { nil }
    assign(:garden_type, garden_type)
    render
  end

  describe "renders a garden_type with no gardens" do
    it { is_expected.to have_content "There are no gardens to display." }
  end
end
