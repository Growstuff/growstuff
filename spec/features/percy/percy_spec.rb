require 'rails_helper'

describe 'Test with visual testing', type: :feature, js: true do
  let(:member)       { FactoryBot.create :member, login_name: 'percy', preferred_avatar_uri: gravatar }
  let(:someone_else) { FactoryBot.create :member, login_name: 'ruby', preferred_avatar_uri: gravatar2 }

  let(:gravatar) { 'http://www.gravatar.com/avatar/d021434aac03a7f7c7c0de60d07dad1c?size=150&default=identicon' }
  let(:gravatar2) { 'http://www.gravatar.com/avatar/353d83d3677b142520987e1936fd093c?size=150&default=identicon' }
  let!(:tomato)   { FactoryBot.create :tomato, creator: someone_else }
  let(:plant_part) { FactoryBot.create :plant_part, name: 'fruit' }

  let(:tomato_photo) do
        FactoryBot.create :photo,
                                  title:         'look at my tomatoes',
                                  owner:         member,
                                  fullsize_url:  'https://farm1.staticflickr.com/177/432250619_2fe19d067d_z.jpg',
                                  thumbnail_url: 'https://farm1.staticflickr.com/177/432250619_2fe19d067d_q.jpg'
  end
  before do
    # Freeze time, so we don't have variations in timestamps on the page
    Timecop.freeze(Time.local(2019, 1, 1))

    {
      chard:    'https://farm9.staticflickr.com/8516/8519911893_1759c28965_q.jpg',
      apple:    'https://farm5.staticflickr.com/4748/38932178855_6fe9bcdb48_q.jpg',
      pear:     'https://farm1.staticflickr.com/113/250984726_0fc31fea6d_q.jpg',
      popcorn:  'https://farm8.staticflickr.com/7893/33150160528_24a689c6bc_q.jpg',
      eggplant: 'https://farm8.staticflickr.com/7856/47068736892_1af9b8a4ba_q.jpg',
      maize:    'https://farm66.staticflickr.com/65535/46739264475_7cb55b2cbb_q.jpg'
    }.each do |crop_type, photo_url|
      crop = FactoryBot.create crop_type, creator: someone_else
      owner = FactoryBot.create :member, login_name: crop_type.to_s.reverse, email: "#{crop.name}@example.com"
      planting = FactoryBot.create :planting, crop: crop, owner: owner, garden: owner.gardens.first
      photo = FactoryBot.create(:photo, owner: owner,
          thumbnail_url: "#{photo_url}_q.jpg", fullsize_url: "#{photo_url}_z.jpg")
      planting.photos << photo

      harvest = FactoryBot.create :harvest, crop: crop, owner: owner, plant_part: plant_part
      harvest.photos << photo
    end
  end
  after { Timecop.return }

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

      it 'gardens#show' do
        # a garden
        garden = FactoryBot.create :garden, name: 'paraside', owner: member
        #with some lettuce (finished)
        FactoryBot.create :planting, crop: FactoryBot.create(:crop, name: 'lettuce'), garden: garden, owner: member, finished_at: 2.weeks.ago
        #tomato still growing
        tomato_planting = FactoryBot.create :planting, garden: garden, owner: member, crop: tomato
        tomato_photo.plantings << tomato_planting
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

    describe 'posts' do
      let(:post) { FactoryBot.create :post, author: member }
      it 'loads posts#show' do
        visit post_path(post)
        Percy.snapshot(page, name: "#{prefix}/posts#show")
      end
      it 'loads posts#index' do
        Member.all.each do |member|
          FactoryBot.create_list :post, 12, author: member
        end
        Post.all.order(:id).limit(4) do |post|
          FactoryBot.create_list :comment, rand(1..5), post: post
        end
        visit posts_path
        Percy.snapshot(page, name: "#{prefix}/posts#index")
      end
    end

    describe 'photos' do
      it 'loads photos#show' do
        tomato_photo.plantings << FactoryBot.create(:planting, owner: member, crop: tomato)
        visit photo_path(tomato_photo)
        Percy.snapshot(page, name: "#{prefix}/photos#show")
      end
    end
  end

  context "when signed out" do
    let(:prefix) { 'signed-out' }
    include_examples 'visit pages'

    it 'loads sign in page' do
      visit crops_path # some random page
      click_link 'Sign in'
      Percy.snapshot(page, name: "sign-in")
    end

    it 'loads sign up page' do
      visit crops_path # some random page
      click_link 'Sign up'
      Percy.snapshot(page, name: "sign-up")
    end

    it 'loads forgot password' do
      visit new_member_password_path
      Percy.snapshot(page, name: "forgot-password")
    end
    it 'loads new confirmation' do
      visit new_member_confirmation_path
      Percy.snapshot(page, name: "new-confimation")
    end
  end

  context 'when signed in' do
    let(:prefix) { 'signed-in' }
    before { login_as member }
    include_examples 'visit pages'

    it 'load my plantings#show' do
      planting = FactoryBot.create :planting, crop: tomato, owner: member, garden: member.gardens.first
      visit planting_path(planting)
      Percy.snapshot(page, name: "#{prefix}/self/plantings#show")
    end

    it 'load my members#show' do
      visit member_path(member)
      Percy.snapshot(page, name: "#{prefix}/self/members#show")
    end

    it 'load my gardens#show' do
      garden = FactoryBot.create :garden, name: 'paradise', owner: member
      visit garden_path(garden)
      Percy.snapshot(page, name: "#{prefix}/self/gardens#show")
    end

    it 'loads plantings#new' do
      visit new_planting_path
      Percy.snapshot(page, name: "#{prefix}/plantings#new")
    end

    describe '#new' do
      it 'loads gardens#new' do
        visit new_garden_path
        Percy.snapshot(page, name: "#{prefix}/gardens#new")
      end

      it 'loads harvests#new' do
        visit new_harvest_path
        Percy.snapshot(page, name: "#{prefix}/harvests#new")
      end

      it 'loads plantings#new' do
        visit new_planting_path
        Percy.snapshot(page, name: "#{prefix}/plantings#new")
      end

      it 'loads posts#new' do
        visit new_post_path
        Percy.snapshot(page, name: "#{prefix}/posts#new")
      end

      it 'loads crops#new' do
        visit new_crop_path
        Percy.snapshot(page, name: "#{prefix}/crops#new")
      end
    end

    describe '#edit' do
      it 'loads gardens#edit' do
        garden = FactoryBot.create :garden, owner: member
        visit edit_garden_path(garden)
        Percy.snapshot(page, name: "#{prefix}/gardens#edit")
      end

      it 'loads harvests#edit' do
        harvest = FactoryBot.create :harvest, owner: member
        visit edit_harvest_path(harvest)
        Percy.snapshot(page, name: "#{prefix}/harvests#edit")
      end

      it 'loads planting#edit' do
        planting = FactoryBot.create :planting, owner: member
        visit edit_planting_path(planting)
        Percy.snapshot(page, name: "#{prefix}/plantings#edit")
      end

      it 'loads posts#edit' do
        post = FactoryBot.create :post, author: member
        visit edit_post_path(post)
        Percy.snapshot(page, name: "#{prefix}/posts#edit")
      end
    end

    describe 'expand menus' do
      it 'expands crop menu' do
        visit root_path
        click_on 'Crops'
        Percy.snapshot(page, name: "#{prefix}/crops-menu")
        click_on 'Community'
        Percy.snapshot(page, name: "#{prefix}/community-menu")
        click_on 'percy'
        Percy.snapshot(page, name: "#{prefix}/member-menu")
      end
    end
  end
end
