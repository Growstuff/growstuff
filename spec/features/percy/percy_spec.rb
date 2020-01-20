# frozen_string_literal: true

require 'rails_helper'

describe 'Test with visual testing', type: :feature, js: true do
  # Use the same random seed every time so our random data is the same
  # on every run, so doesn't trigger percy to see changes
  before { Faker::Config.random = Random.new(42) }
  let!(:member)        { FactoryBot.create :member, login_name: 'percy', preferred_avatar_uri: gravatar }
  let!(:crop_wrangler) { FactoryBot.create :crop_wrangling_member, login_name: 'croppy', preferred_avatar_uri: gravatar2 }
  let!(:admin_user) { FactoryBot.create :admin_member, login_name: 'janitor', preferred_avatar_uri: gravatar3 }
  let!(:someone_else) { FactoryBot.create :edinburgh_member, login_name: 'ruby', preferred_avatar_uri: gravatar4 }

  let(:gravatar) { 'https://secure.gravatar.com/avatar/d021434aac03a7f7c7c0de60d07dad1c?size=150&default=identicon' }
  let(:gravatar2) { 'https://secure.gravatar.com/avatar/353d83d3677b142520987e1936fd093c?size=150&default=identicon' }
  let(:gravatar3) { 'https://secure.gravatar.com/avatar/622db62c7beab8d5d8b7a80aa6385b2f?size=150&default=identicon' }
  let(:gravatar4) { 'https://secure.gravatar.com/avatar/7fd767571ff5ceefc7a687a543b2c402?size=150&default=identicon' }

  let!(:tomato)   { FactoryBot.create :tomato, creator: someone_else }
  let(:plant_part) { FactoryBot.create :plant_part, name: 'fruit' }

  let(:tomato_photo) do
    FactoryBot.create :photo,
                      title:         'look at my tomatoes',
                      owner:         member,
                      fullsize_url:  'https://farm1.staticflickr.com/177/432250619_2fe19d067d_z.jpg',
                      thumbnail_url: 'https://farm1.staticflickr.com/177/432250619_2fe19d067d_q.jpg'
  end
  let(:post_body) do
    "So, um, watering's important. Yep. Very important.

Well, what with moving into the house and all THAT entails...my plants
are looking the worse for wear. They haven't gotten enough water. The
oregano is dead. The basil and chives are just hanging on. The
[tomato](crop) have sort of purple leaves. Seeing that the roots were all
growing out of the bottom of the pots, I finally went and got soil
to fill the basins I have for the tomatoes and spent the money on proper
(much larger) pots for the herbs.

At Home Depot, it turned out that 7.5\" pots that are glazed inside and out
(to prevent wicking & evaporation of water -- the problem my tomatoes
were hitting with the teensy clay pots) were $10 for the pot and $5
for the saucer. Or there are 7.25\" self-watering pots for $15. So my
  herbs are now in self-watering pots where they should be able to
  survive Pennsic without me.  I got a new oregano plant too.

[ ![self-watering herbs](http://farm4.staticflickr.com/3735/9337893326_62a036bf56.jpg) ](http://www.flickr.com/photos/maco_nix/9337893326/)

The tomatoes are now in large plastic bins full of dirt/compost, where
their roots can spread out. Turns out clay pots in weather that is always over 80,
usually over 90, and hitting over 100 (celsius people, read those as 26, 32, 38)
means you need to water at least daily, probably a couple of times a day, to keep
the plants happy.

[ ![tomatoes in plastic cement mixing tubs](http://farm4.staticflickr.com/3745/9337878942_9602530c31.jpg)](http://www.flickr.com/photos/maco_nix/9337878942/)

After taking that photo, I put some egg shells (since I hardboiled some eggs
today for pickling) in the dirt around them and added stakes.

I noticed a couple of days ago on the way to work that there's a place near
home called Country Boy Market. Fresh locally grown produce (cheap berries, nom nom),
mulch, top soil, compost, and straw bales are all available. Also they deliver mulch
& soil. Well then. I know what's happening next spring when I try to build up the
rest of the garden.
[apple](crop)
    "
  end
  let(:post) { FactoryBot.create :post, author: member, subject: "Watering", body: post_body }
  before do
    # Freeze time, so we don't have variations in timestamps on the page
    Timecop.freeze(Time.zone.local(2019, 1, 1))

    {
      chard:    'https://farm9.staticflickr.com/8516/8519911893_1759c28965_q.jpg',
      apple:    'https://farm5.staticflickr.com/4748/38932178855_6fe9bcdb48_q.jpg',
      pear:     'https://farm1.staticflickr.com/113/250984726_0fc31fea6d_q.jpg',
      popcorn:  'https://farm8.staticflickr.com/7893/33150160528_24a689c6bc_q.jpg',
      eggplant: 'https://farm8.staticflickr.com/7856/47068736892_1af9b8a4ba_q.jpg',
      maize:    'https://farm66.staticflickr.com/65535/46739264475_7cb55b2cbb_q.jpg'
    }.each do |crop_type, photo_url|
      crop = FactoryBot.create crop_type, creator: someone_else
      crop.reindex
      owner = FactoryBot.create :interesting_member, login_name: crop_type.to_s.reverse, email: "#{crop.name}@example.com"
      planting = FactoryBot.create :planting, crop: crop, owner: owner, garden: owner.gardens.first
      photo = FactoryBot.create(:photo, owner: owner,
                                        thumbnail_url: "#{photo_url}_q.jpg", fullsize_url: "#{photo_url}_z.jpg")
      planting.photos << photo

      harvest = FactoryBot.create :harvest, crop: crop, owner: owner, plant_part: plant_part
      harvest.photos << photo
      FactoryBot.create :planting, crop: tomato,
                                   planted_at: 1.year.ago, finished_at: 2.months.ago,
                                   sunniness: 'sun', planted_from: 'seed'
    end

    FactoryBot.create :seed, owner: member, tradable_to: 'nationally'
    FactoryBot.create :seed, owner: someone_else, tradable_to: 'nationally'
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
        FactoryBot.create :planting, planted_at: 2.months.ago, sunniness: 'shade', planted_from: 'seedling'

        planting = FactoryBot.create :planting, planted_at: 1.year.ago, sunniness: 'sun', planted_from: 'seed', crop: tomato
        FactoryBot.create(:harvest,
                          crop:         tomato,
                          plant_part:   FactoryBot.create(:plant_part, name: 'berry'),
                          planting:     planting,
                          harvested_at: 1.day.ago)

        post = FactoryBot.create :post, subject: 'tomatoes are delicious'
        tomato.posts << post

        visit crop_path(tomato)
        expect(page).to have_text 'tomato'
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
        garden = FactoryBot.create :garden, name: 'paradise', owner: member
        # with some lettuce (finished)
        FactoryBot.create(
          :planting, crop: FactoryBot.create(:crop, name: 'lettuce'),
                     garden: garden, owner: member, finished_at: 2.weeks.ago
        )
        # tomato still growing
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
        FactoryBot.create :planting, owner: someone_else, created_at: 30.days.ago, crop: tomato
        FactoryBot.create :planting, owner: someone_else, created_at: 24.days.ago, crop: tomato
        FactoryBot.create :post, author: someone_else, created_at: 4.days.ago, subject: 'waiting for my tomatoes'
        FactoryBot.create :harvest, owner: someone_else, created_at: 1.day.ago, crop: tomato

        visit member_path(someone_else)
        Percy.snapshot(page, name: "#{prefix}/members#show")
      end
    end

    describe 'posts' do
      it 'loads posts#show' do
        FactoryBot.create :comment, post: post
        FactoryBot.create :comment, post: post
        visit post_path(post)
        Percy.snapshot(page, name: "#{prefix}/posts#show")
      end
      it 'loads posts#index' do
        Member.all.limit(5).each do |member|
          FactoryBot.create_list :post, 12, author: member
        end
        Post.all.order(id: :desc).limit(4) do |post|
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
    include_context 'signed in member'
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

    describe '#new' do
      it 'crops#new' do
        visit new_crop_path
        Percy.snapshot(page, name: "#{prefix}/crops#new")
      end

      it 'gardens#new' do
        visit new_garden_path
        Percy.snapshot(page, name: "#{prefix}/gardens#new")
      end

      it 'harvests#new' do
        visit new_harvest_path
        Percy.snapshot(page, name: "#{prefix}/harvests#new")
        fill_in(id: 'crop', with: 'tom')
        Percy.snapshot(page, name: "#{prefix}/harvests#new-autosuggest")
      end

      it 'plantings#new' do
        visit new_planting_path
        Percy.snapshot(page, name: "#{prefix}/plantings#new")
        fill_in(id: 'crop', with: 'tom')
        Percy.snapshot(page, name: "#{prefix}/plantings#new-autosuggest")
      end

      it 'seeds#new' do
        visit new_seed_path
        Percy.snapshot(page, name: "#{prefix}/seeds#new")
        fill_in(id: 'crop', with: 'tom')
        Percy.snapshot(page, name: "#{prefix}/seeds#new-autosuggest")
      end

      it 'posts#new' do
        visit new_post_path
        Percy.snapshot(page, name: "#{prefix}/posts#new")
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
        visit edit_post_path(post)
        Percy.snapshot(page, name: "#{prefix}/posts#edit")
      end

      it 'comments#new' do
        visit new_comment_path(post_id: post.id)
        Percy.snapshot(page, name: "comments#new")
      end
    end

    describe 'expand menus' do
      it 'expands crop menu' do
        member.update! login_name: 'percy'
        visit root_path
        click_on 'Crops'
        Percy.snapshot(page, name: "#{prefix}/crops-menu")
        click_on 'Community'
        Percy.snapshot(page, name: "#{prefix}/community-menu")
        click_on 'percy', class: 'nav-link'
        Percy.snapshot(page, name: "#{prefix}/member-menu")
      end
    end
  end

  context 'wrangling crops' do
    include_context 'signed in crop wrangler'
    let!(:candy) { FactoryBot.create :crop_request, name: 'candy' }

    it 'crop wrangling page' do
      visit wrangle_crops_path
      Percy.snapshot(page, name: 'crops wrangle')
      click_link 'Pending approval'
      Percy.snapshot(page, name: 'crops pending approval')
      click_link 'candy'
      Percy.snapshot(page, name: 'editing pending crop')
    end
  end

  context 'admin' do
    include_context 'signed in admin'
    before { visit admin_path }
    it 'admin page' do
      Percy.snapshot(page, name: 'Admin')
    end
    it 'Roles' do
      click_link 'Roles'
      Percy.snapshot(page, name: 'Admin Roles')
    end
    it 'CMS' do
      click_link 'CMS'
      Percy.snapshot(page, name: 'CMS')
    end
    it 'Garden Types' do
      click_link 'Garden Types'
      Percy.snapshot(page, name: 'Admin Garden type')
    end
    it 'Alternate names' do
      click_link 'Alternate names'
      Percy.snapshot(page, name: 'Admin Alternate names')
    end
    it 'Scientific names' do
      click_link 'Scientific names'
      Percy.snapshot(page, name: 'Admin Scientific names')
    end
    it 'Members' do
      click_link 'Members'
      Percy.snapshot(page, name: 'Admin Members')
    end
  end

  it 'api docs' do
    visit '/api-docs'
    Percy.snapshot(page, name: 'api docs')
  end
end
