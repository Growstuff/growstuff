require 'rails_helper'

describe "browse crops" do
  let!(:tomato)         { FactoryBot.create :tomato        }
  let!(:maize)          { FactoryBot.create :maize         }
  let!(:pending_crop)   { FactoryBot.create :crop_request  }
  let!(:rejected_crop)  { FactoryBot.create :rejected_crop }

  it "has a form for sorting by" do
    visit crops_path
    expect(page).to have_css "select#sort"
  end

  it "shows a list of crops" do
    visit crops_path
    expect(page).to have_content tomato.name
  end

  it "pending crops are not listed" do
    visit crops_path
    expect(page).not_to have_content pending_crop.name
  end

  it "rejected crops are not listed" do
    visit crops_path
    expect(page).not_to have_content rejected_crop.name
  end

  include_context 'signed in crop wrangler' do
    before { visit crops_path }

    it "shows a new crop link" do
      expect(page).to have_link "Add New Crop"
    end
  end
end
