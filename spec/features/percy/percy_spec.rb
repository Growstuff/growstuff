# frozen_string_literal: true

require 'rails_helper'

describe 'Test with visual testing', :js do
  # Use the same random seed every time so our random data is the same
  # on every run, so doesn't trigger percy to see changes
  before { Faker::Config.random = Random.new(42) }

  let!(:member)        { create(:member, login_name: 'percy', preferred_avatar_uri: member_gravatar) }
  let!(:crop_wrangler) { create(:crop_wrangling_member, login_name: 'croppy', preferred_avatar_uri: crop_wrangler_gravatar) }
  let!(:admin_user) { create(:admin_member, login_name: 'janitor', preferred_avatar_uri: admin_gravatar) }
  let!(:someone_else) { create(:edinburgh_member, login_name: 'ruby', preferred_avatar_uri: someone_else_gravatar) }

  let(:member_gravatar) { 'https://secure.gravatar.com/avatar/d021434aac03a7f7c7c0de60d07dad1c?size=150&default=identicon' }
  let(:crop_wrangler_gravatar) { 'https://secure.gravatar.com/avatar/353d83d3677b142520987e1936fd093c?size=150&default=identicon' }
  let(:admin_gravatar) { 'https://secure.gravatar.com/avatar/622db62c7beab8d5d8b7a80aa6385b2f?size=150&default=identicon' }
  let(:someone_else_gravatar) { 'https://secure.gravatar.com/avatar/7fd767571ff5ceefc7a687a543b2c402?size=150&default=identicon' }

  let!(:tomato) { create(:tomato, creator: someone_else) }
  let(:plant_part) { create(:plant_part, name: 'fruit') }

  let(:tomato_photo) do
    create(:photo,
           title:         'look at my tomatoes',
           owner:         member,
           fullsize_url:  'https://farm1.staticflickr.com/177/432250619_2fe19d067d_z.jpg',
           thumbnail_url: 'https://farm1.staticflickr.com/177/432250619_2fe19d067d_q.jpg')
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
  let(:post) { create(:post, author: member, subject: "Watering", body: post_body) }

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
      crop = create(crop_type, creator: someone_else)
      crop.reindex
      owner = create(:interesting_member, login_name: crop_type.to_s.reverse, email: "#{crop.name}@example.com")
      planting = create(:planting, crop:, owner:, garden: owner.gardens.first)
      photo = create(:photo, owner:,
                                        thumbnail_url: "#{photo_url}_q.jpg", fullsize_url: "#{photo_url}_z.jpg")
      planting.photos << photo

      harvest = create(:harvest, crop:, owner:, plant_part:)
      harvest.photos << photo
      create(:planting, crop: tomato,
                                   planted_at: 1.year.ago, finished_at: 2.months.ago,
                                   sunniness: 'sun', planted_from: 'seed')
    end

    create(:seed, owner: member, tradable_to: 'nationally')
    create(:seed, owner: someone_else, tradable_to: 'nationally')
  end

  after { Timecop.return }

  shared_examples 'visit pages' do
    describe 'home' do
      it 'loads homepage' do
        visit root_path
        page.percy_snapshot(page, name: "#{prefix}/homepage")
      end
    end

    describe 'crops' do
      it 'loads crops#show' do
        create(:planting, planted_at: 2.months.ago, sunniness: 'shade', planted_from: 'seedling')

        planting = create(:planting, planted_at: 1.year.ago, sunniness: 'sun', planted_from: 'seed', crop: tomato)
        create(:harvest,
               crop:         tomato,
               plant_part:   create(:plant_part, name: 'berry'),
               planting:,
               harvested_at: 1.day.ago)

        post = create(:post, subject: 'tomatoes are delicious')
        tomato.posts << post

        visit crop_path(tomato)
        expect(page).to have_text 'tomato'
        page.percy_snapshot(page, name: "#{prefix}/crops#show")
      end

      it 'loads crops#index' do
        visit crops_path
        page.percy_snapshot(page, name: "#{prefix}/crops#index")
      end
    end

    describe 'plantings' do
      it 'loads plantings#index' do
        visit plantings_path
        page.percy_snapshot(page, name: "#{prefix}/plantings#index")
      end

      it 'load another member plantings#show' do
        planting = create(:planting, crop: tomato, owner: someone_else, garden: someone_else.gardens.first)
        visit planting_path(planting)
        page.percy_snapshot(page, name: "#{prefix}/plantings#show")
      end
    end

    describe 'gardens' do
      it 'loads gardens#index' do
        visit gardens_path
        page.percy_snapshot(page, name: "#{prefix}/gardens#index")
      end

      it 'gardens#show' do
        # a garden
        garden = create(:garden, name: 'paradise', owner: member)
        # with some lettuce (finished)
        create(
          :planting, crop: create(:crop, name: 'lettuce'),
                     garden:, owner: member, finished_at: 2.weeks.ago
        )
        # tomato still growing
        tomato_planting = create(:planting, garden:, owner: member, crop: tomato)
        tomato_photo.plantings << tomato_planting
        visit garden_path(garden)
        page.percy_snapshot(page, name: "#{prefix}/gardens#show")
      end
    end

    describe 'members' do
      it 'loads members#index' do
        visit members_path
        page.percy_snapshot(page, name: "#{prefix}/members#index")
      end

      it 'loads another members#show' do
        create(:planting, owner: someone_else, created_at: 30.days.ago, crop: tomato)
        create(:planting, owner: someone_else, created_at: 24.days.ago, crop: tomato)
        create(:post, author: someone_else, created_at: 4.days.ago, subject: 'waiting for my tomatoes')
        create(:harvest, owner: someone_else, created_at: 1.day.ago, crop: tomato)

        visit member_path(someone_else)
        page.percy_snapshot(page, name: "#{prefix}/members#show")
      end
    end

    describe 'posts' do
      it 'loads posts#show' do
        create(:comment, commentable: post)
        create(:comment, commentable: post)
        visit post_path(post)
        page.percy_snapshot(page, name: "#{prefix}/posts#show")
      end

      it 'loads posts#index' do
        Member.all.limit(5).each do |member|
          create_list(:post, 12, author: member)
        end
        Post.all.order(id: :desc).limit(4) do |post|
          create_list(:comment, rand(1..5), commentable: post)
        end
        visit posts_path
        page.percy_snapshot(page, name: "#{prefix}/posts#index")
      end
    end

    describe 'photos' do
      it 'loads photos#show' do
        tomato_photo.plantings << create(:planting, owner: member, crop: tomato)
        visit photo_path(tomato_photo)
        page.percy_snapshot(page, name: "#{prefix}/photos#show")
      end
    end
  end

  context "when signed out" do
    let(:prefix) { 'signed-out' }

    it_behaves_like 'visit pages'

    it 'loads sign in page' do
      visit crops_path # some random page
      click_link 'Sign in'
      page.percy_snapshot(page, name: "sign-in")
    end

    it 'loads sign up page' do
      visit crops_path # some random page
      click_link 'Sign up'
      page.percy_snapshot(page, name: "sign-up")
    end

    it 'loads forgot password' do
      visit new_member_password_path
      page.percy_snapshot(page, name: "forgot-password")
    end

    it 'loads new confirmation' do
      visit new_member_confirmation_path
      page.percy_snapshot(page, name: "new-confimation")
    end
  end

  context 'when signed in' do
    let(:prefix) { 'signed-in' }

    include_context 'signed in member'
    it_behaves_like 'visit pages'

    it 'load my plantings#show' do
      planting = create(:planting, crop: tomato, owner: member, garden: member.gardens.first)
      visit planting_path(planting)
      page.percy_snapshot(page, name: "#{prefix}/self/plantings#show")
    end

    it 'load my members#show' do
      visit member_path(member)
      page.percy_snapshot(page, name: "#{prefix}/self/members#show")
    end

    it 'load my gardens#show' do
      garden = create(:garden, name: 'paradise', owner: member)
      visit garden_path(garden)
      page.percy_snapshot(page, name: "#{prefix}/self/gardens#show")
    end

    describe '#new' do
      it 'crops#new' do
        visit new_crop_path
        page.percy_snapshot(page, name: "#{prefix}/crops#new")
      end

      it 'gardens#new' do
        visit new_garden_path
        page.percy_snapshot(page, name: "#{prefix}/gardens#new")
      end

      it 'harvests#new' do
        visit new_harvest_path
        page.percy_snapshot(page, name: "#{prefix}/harvests#new")
        fill_in(id: 'crop', with: 'tom')
        page.percy_snapshot(page, name: "#{prefix}/harvests#new-autosuggest")
      end

      it 'plantings#new' do
        visit new_planting_path
        page.percy_snapshot(page, name: "#{prefix}/plantings#new")
        fill_in(id: 'crop', with: 'tom')
        page.percy_snapshot(page, name: "#{prefix}/plantings#new-autosuggest")
      end

      it 'seeds#new' do
        visit new_seed_path
        page.percy_snapshot(page, name: "#{prefix}/seeds#new")
        fill_in(id: 'crop', with: 'tom')
        page.percy_snapshot(page, name: "#{prefix}/seeds#new-autosuggest")
      end

      it 'posts#new' do
        visit new_post_path
        page.percy_snapshot(page, name: "#{prefix}/posts#new")
      end
    end

    describe '#edit' do
      it 'loads gardens#edit' do
        garden = create(:garden, owner: member)
        visit edit_garden_path(garden)
        page.percy_snapshot(page, name: "#{prefix}/gardens#edit")
      end

      it 'loads harvests#edit' do
        harvest = create(:harvest, owner: member)
        visit edit_harvest_path(harvest)
        page.percy_snapshot(page, name: "#{prefix}/harvests#edit")
      end

      it 'loads planting#edit' do
        planting = create(:planting, owner: member)
        visit edit_planting_path(planting)
        page.percy_snapshot(page, name: "#{prefix}/plantings#edit")
      end

      it 'loads posts#edit' do
        visit edit_post_path(post)
        page.percy_snapshot(page, name: "#{prefix}/posts#edit")
      end

      it 'comments#new' do
        visit new_comment_path(comment: { commentable_type: Post, commentable_id: post.id })
        page.percy_snapshot(page, name: "comments#new")
      end
    end

    describe 'expand menus' do
      it 'expands crop menu' do
        member.update! login_name: 'percy'
        visit root_path
        click_on 'Crops'
        page.percy_snapshot(page, name: "#{prefix}/crops-menu")
        click_on 'Community'
        page.percy_snapshot(page, name: "#{prefix}/community-menu")
        click_on 'percy', class: 'nav-link'
        page.percy_snapshot(page, name: "#{prefix}/member-menu")
      end
    end
  end

  context 'wrangling crops' do
    include_context 'signed in crop wrangler'
    let!(:candy) { create(:crop_request, name: 'candy') }

    it 'crop wrangling page' do
      visit wrangle_crops_path
      page.percy_snapshot(page, name: 'crops wrangle')
      click_link 'Pending approval'
      page.percy_snapshot(page, name: 'crops pending approval')
      click_link 'candy'
      page.percy_snapshot(page, name: 'editing pending crop')
    end
  end

  context 'admin' do
    include_context 'signed in admin'
    before { visit admin_path }

    it 'admin page' do
      page.percy_snapshot(page, name: 'Admin')
    end

    it 'Roles' do
      click_link 'Roles'
      page.percy_snapshot(page, name: 'Admin Roles')
    end

    it 'CMS' do
      click_link 'CMS'
      page.percy_snapshot(page, name: 'CMS')
    end

    it 'Garden Types' do
      click_link 'Garden Types'
      page.percy_snapshot(page, name: 'Admin Garden type')
    end

    it 'Alternate names' do
      click_link 'Alternate names'
      page.percy_snapshot(page, name: 'Admin Alternate names')
    end

    it 'Scientific names' do
      click_link 'Scientific names'
      page.percy_snapshot(page, name: 'Admin Scientific names')
    end

    it 'Members' do
      click_link 'Members'
      page.percy_snapshot(page, name: 'Admin Members')
    end
  end

  it 'api docs' do
    visit '/api-docs'
    page.percy_snapshot(page, name: 'api docs')
  end
end
