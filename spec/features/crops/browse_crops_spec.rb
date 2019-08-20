require 'rails_helper'

describe "browse crops" do
  let!(:tomato)         { FactoryBot.create :tomato        }
  let!(:maize)          { FactoryBot.create :maize         }
  let!(:pending_crop)   { FactoryBot.create :crop_request  }
  let!(:rejected_crop)  { FactoryBot.create :rejected_crop }

  shared_examples 'shows crops' do
    before { visit crops_path }
    it "has a form for sorting by" do
      expect(page).to have_css "select#sort"
    end

    it "shows a list of crops" do
      expect(page).to have_content tomato.name
    end

    it "pending crops are not listed" do
      expect(page).not_to have_content pending_crop.name
    end

    it "rejected crops are not listed" do
      expect(page).not_to have_content rejected_crop.name
    end
  end

  shared_examples 'add new crop' do
    it "shows a new crop link" do
      expect(page).to have_link "Add New Crop"
    end
  end

  context 'anon' do
    include_examples 'shows crops'
    it { expect(page).not_to have_link "Add New Crop" }
  end

  context 'member' do
    include_context 'signed in member'
    include_examples 'shows crops'
    include_examples 'add new crop'
  end

  context 'wrangler' do
    include_context 'signed in crop wrangler'
    include_examples 'shows crops'
    include_examples 'add new crop'
  end

  context 'admin' do
    include_context 'signed in admin'
    include_examples 'shows crops'
    include_examples 'add new crop'
  end
end
