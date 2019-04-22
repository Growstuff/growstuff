require 'rails_helper'

describe 'Test with visual testing', type: :feature, js: true do
  let(:member) { FactoryBot.create :member, login_name: 'percy', preferred_avatar_uri: gravatar }
  let(:someone_else) { FactoryBot.create :member, login_name: 'ruby', preferred_avatar_uri: gravatar2 }

  let(:gravatar) { 'http://www.gravatar.com/avatar/d021434aac03a7f7c7c0de60d07dad1c?size=150&default=identicon' }
  let(:gravatar2) { 'http://www.gravatar.com/avatar/353d83d3677b142520987e1936fd093c?size=150&default=identicon' }
  let!(:tomato) { FactoryBot.create :tomato }
  before do
    {
      chard:    'https://farm9.staticflickr.com/8516/8519911893_1759c28965_q.jpg',
      apple:    'https://farm5.staticflickr.com/4748/38932178855_6fe9bcdb48_q.jpg',
      pear:     'https://farm1.staticflickr.com/113/250984726_0fc31fea6d_q.jpg',
      popcorn:  'https://farm8.staticflickr.com/7893/33150160528_24a689c6bc_q.jpg',
      eggplant: 'https://farm8.staticflickr.com/7856/47068736892_1af9b8a4ba_q.jpg',
      maize:    'https://farm66.staticflickr.com/65535/46739264475_7cb55b2cbb_q.jpg'
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

      it 'load another member plantings#show' do
        planting = FactoryBot.create :planting, crop: tomato, owner: someone_else, garden: someone_else.gardens.first
        visit planting_path(planting)
        Percy.snapshot(page, name: "#{prefix}/plantings#show")
      end
    end

    describe 'gardens' do
      it 'loads gardens#index' do
        visit gardens_path
        Percy.snapshot(page, name: "#{prefix}/gardens#index")
      end

      it 'load some one else\'s gardens#show' do
        garden = FactoryBot.create :garden, name: 'paraside', owner: someone_else
        visit garden_path(garden)
        Percy.snapshot(page, name: "#{prefix}/gardens#show")
      end
    end

    describe 'members' do
      it 'loads members#index' do
        visit members_path
        Percy.snapshot(page, name: "#{prefix}/members#index")
      end

      it 'loads another members#show' do
        visit member_path(someone_else)
        Percy.snapshot(page, name: "#{prefix}/members#show")
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

    it 'load plantings#show' do
      planting = FactoryBot.create :planting, crop: tomato, owner: member, garden: member.gardens.first
      visit planting_path(planting)
      Percy.snapshot(page, name: "#{prefix}/self/plantings#show")
    end

    it 'load members#show' do
      visit member_path(member)
      Percy.snapshot(page, name: "#{prefix}/self/members#show")
    end

    it 'load my gardens#show' do
      garden = FactoryBot.create :garden, name: 'paradise', owner: member
      visit garden_path(garden)
      Percy.snapshot(page, name: "#{prefix}/self/gardens#show")
    end
  end
end
