require 'rails_helper'

describe 'Test with visual testing', type: :feature, js: true do
  let(:member) { FactoryBot.create :member, login_name: 'percy' }
  let!(:tomato) { FactoryBot.create :tomato }
  before do
    {
      chard: 'https://farm9.staticflickr.com/8516/8519911893_1759c28965_q.jpg',
      apple: 'https://farm5.staticflickr.com/4748/38932178855_6fe9bcdb48_q.jpg',
      pear: 'https://farm1.staticflickr.com/113/250984726_0fc31fea6d_q.jpg',
      popcorn: 'https://farm8.staticflickr.com/7893/33150160528_24a689c6bc_q.jpg',
      eggplant: 'https://farm8.staticflickr.com/7856/47068736892_1af9b8a4ba_q.jpg',
      maize: 'https://farm66.staticflickr.com/65535/46739264475_7cb55b2cbb_q.jpg'
    }.each do |crop_type, photo_url|
      crop = FactoryBot.create crop_type
      owner = FactoryBot.create :member, login_name: crop_type.to_s.reverse, email: "#{crop.name}@example.com"
      planting = FactoryBot.create :planting, crop: crop, owner: owner, garden: owner.gardens.first
      planting.photos << FactoryBot.create(:photo, owner: owner, thumbnail_url: photo_url)
    end
  end

  shared_examples 'visit pages' do
    describe 'home' do
      it 'loads homepage' do
        visit root_path
        Percy.snapshot(page, name: "#{prefix}/homepage")
      end
    end

    describe 'crops' do
      it 'loads crops#show' do
        visit crop_path(tomato)
        Percy.snapshot(page, name: "#{prefix}/crops#show")
      end
      it 'loads crops#index' do
        visit crops_path
        Percy.snapshot(page, name: "#{prefix}/crops#index")
     end
   end

   describe 'plantings' do
     it 'loads plantings#index' do
       visit plantings_path
        Percy.snapshot(page, name: "#{prefix}/plantings#index")
     end

     it 'load plantings#show' do
       planting = FactoryBot.create :planting, crop: tomato, owner: member, garden: member.gardens.first
       visit planting_path(planting)
        Percy.snapshot(page, name: "#{prefix}/plantings#show")
     end
   end
  end

  context "when signed out" do
    let(:prefix) { 'signed-out' }
    include_examples 'visit pages'
  end

  context 'when signed in' do
    let(:prefix) { 'signed-in' }
    before { login_as member }
    include_examples 'visit pages'
  end
end
