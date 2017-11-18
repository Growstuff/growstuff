require 'rails_helper'

describe "scientific_names/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @scientific_name = assign(:scientific_name,
      FactoryBot.create(:zea_mays))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Zea mays/)
  end

  context 'signed in' do
    before :each do
      @wrangler = FactoryBot.create(:crop_wrangling_member)
      sign_in @wrangler
      controller.stub(:current_user) { @wrangler }
      render
    end

    it 'should have an edit button' do
      rendered.should have_content 'Edit'
    end
  end
end
