require 'spec_helper'

feature "Alternate names" do
  let(:alternate_eggplant) { FactoryGirl.create(:alternate_eggplant) }

  scenario "Display alternate names on crop page" do
    visit crop_path(alternate_eggplant.crop)
    expect(page).to have_content alternate_eggplant.name
  end
end
