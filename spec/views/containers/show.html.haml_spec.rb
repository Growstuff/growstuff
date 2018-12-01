require 'rails_helper'

describe "containers/show" do
  subject { render }

  let!(:container) { FactoryBot.create(:container, description: "Hot Sauce") }

  before do
    controller.stub(:current_user) { nil }
    assign(:container, container)
    render
  end

  describe "renders a container with no gardens" do
    it { is_expected.to have_content "There are no gardens to display." }
  end
end
