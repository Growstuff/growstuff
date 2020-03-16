# frozen_string_literal: true

require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the ButtonsHelper. For example:
#
# describe ButtonsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ButtonsHelper, type: :helper do
  before { allow(self).to receive(:can?).and_return(true) }

  let(:garden)   { FactoryBot.create :garden   }
  let(:planting) { FactoryBot.create :planting }
  let(:harvest)  { FactoryBot.create :harvest  }
  let(:seed)     { FactoryBot.create :seed     }

  describe 'add_photo_button' do
    it { expect(add_photo_button(garden)).to include "/photos/new?id=#{garden.id}&amp;type=garden" }
    it { expect(add_photo_button(planting)).to include "/photos/new?id=#{planting.id}&amp;type=planting" }
    it { expect(add_photo_button(harvest)).to include "/photos/new?id=#{harvest.id}&amp;type=harvest" }
    it { expect(add_photo_button(seed)).to include "/photos/new?id=#{seed.id}&amp;type=seed" }
  end

  describe 'edit_button' do
    it { expect(garden_edit_button(garden)).to include "/gardens/#{garden.slug}/edit" }
    it { expect(planting_edit_button(planting)).to include "/plantings/#{planting.slug}/edit" }
    it { expect(harvest_edit_button(harvest)).to include "/harvests/#{harvest.slug}/edit" }
    it { expect(seed_edit_button(seed)).to include "/seeds/#{seed.slug}/edit" }
  end
end
