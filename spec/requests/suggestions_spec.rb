# frozen_string_literal: true

require 'rails_helper'

# The page of the climate through the year and the crops to grow in each season, and the switch for turning suggestions off.
describe 'Crop suggestions' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }

  # The props of the island that shows the seasons.
  def island_props
    element = Capybara.string(response.body).find('[data-react-component="SeasonSuggestions"]', visible: :all)
    JSON.parse(element['data-props'])
  end

  context 'when signed in' do
    before { sign_in member }

    %i(en de es fr ja zh).each do |locale|
      context "with the #{locale} locale" do
        it 'renders the title without interpolation arguments' do
          I18n.with_locale(locale) { get suggestions_path(locale: locale) }

          expect(Capybara.string(response.body))
            .to have_css('h1', text: I18n.t('suggestions.index.title', locale: locale, raise: true))
        end
      end
    end

    it 'turns suggestions off' do
      patch my_suggestions_path, params: { suggest: false }
      expect(member.reload.suggest_crops).to be false
    end

    it 'turns suggestions back on' do
      member.update_columns(suggest_crops: false)
      patch my_suggestions_path, params: { suggest: true }
      expect(member.reload.suggest_crops).to be true
    end

    it 'says so when suggestions are turned off' do
      patch my_suggestions_path, params: { suggest: false }
      expect(flash[:notice]).to eq "We've stopped suggesting crops."
    end

    it 'asks for a location before suggesting anything' do
      get suggestions_path
      expect(response.body).to include 'Tell us where you garden and we can suggest what to sow.'
    end

    context 'with a location' do
      before { member.update_columns(latitude: -41.3, longitude: 174.7, location: 'Wellington, New Zealand') }

      it 'says the weather is being collected when none is held for the place yet' do
        get suggestions_path
        expect(response.body).to include 'any climate data for'
      end

      it 'asks for the weather of the place to be fetched first' do
        get suggestions_path
        expect(ClimateRequest.pluck(:latitude, :longitude)).to eq [[-41.25, 174.75]]
      end

      it 'asks for nothing when the place has weather' do
        create(:climate_month, latitude: -41.25, longitude: 174.75, year: Time.zone.today.year - 1, month: 7)
        get suggestions_path
        expect(ClimateRequest.count).to eq 0
      end

      it 'links the place name to its page while the weather is collected' do
        get suggestions_path
        expect(response.body).to include 'href="/places/Wellington,%20New%20Zealand"'
      end

      it 'gives the island the four seasons when the place has weather' do
        create(:climate_month, year: Time.zone.today.year - 1, month: 7)
        get suggestions_path
        expect(island_props['seasons'].size).to eq 4
      end

      it 'names the place' do
        create(:climate_month, year: Time.zone.today.year - 1, month: 7)
        get suggestions_path
        expect(response.body).to include '>Wellington</a>'
      end

      context 'with a crop whose best temperature suits every season' do
        include ActiveSupport::Testing::TimeHelpers

        let(:record) { create(:ecocrop_data, topmn: 12, topmx: 18, gmin: 30, tmin: 0, tmax: 40) }
        let!(:crop) { create(:crop, name: 'Wintery kale', ecocrop_record: record) }

        before do
          Rails.cache.clear # what gardeners nearby plant is cached, and earlier examples have cached none
          (1..12).each { |month| create(:climate_month, year: 2025, month:, temp_mean_c: 10, temp_min_c: 5, temp_max_c: 15) }
        end

        around { |example| travel_to(Date.new(2026, 11, 10)) { example.run } }

        def crops_of(props, group = 'optimal')
          props['initial'].values.first['groups'].find { |each| each['key'] == group }['crops']
        end

        it 'opens the current season by default' do
          get suggestions_path
          expect(island_props['open']).to eq 'spring'
        end

        it 'opens the season asked for' do
          get suggestions_path(season: 'winter')
          expect(island_props['open']).to eq 'winter'
        end

        it 'opens the current season for a season that is not one' do
          get suggestions_path(season: 'monsoon')
          expect(island_props['open']).to eq 'spring'
        end

        it 'sends the crops of the open season only' do
          get suggestions_path
          expect(island_props['initial'].keys).to eq ['spring']
        end

        it 'lists the crop for the open season' do
          get suggestions_path
          expect(crops_of(island_props).pluck('name')).to eq ['Wintery kale']
        end

        it 'says the temperatures the crop grows best in' do
          get suggestions_path
          expect(crops_of(island_props).first['note']).to eq 'Best at 12–18°'
        end

        it 'says how long the crop takes and when it is ready' do
          record.update!(gmin: 90, gmax: 120)
          get suggestions_path
          expect(crops_of(island_props).first['timing']).to eq '90 to 120 days, ready in early summer'
        end

        it 'gives no timing for a cycle of zero days' do
          record.update!(gmin: 0, gmax: 0)
          get suggestions_path
          expect(crops_of(island_props)).to be_empty
        end

        it 'says the crop is not growing' do
          get suggestions_path
          expect(crops_of(island_props).first['growing']).to be false
        end

        it 'says so when the member has it growing' do
          garden = create(:garden, owner: member)
          create(:planting, crop:, garden:, owner: member, planted_at: Date.new(2026, 10, 1))
          get suggestions_path
          expect(crops_of(island_props).first['growing']).to be true
        end

        it 'says nothing of earlier years when the member has not grown it' do
          get suggestions_path
          expect(crops_of(island_props).first['grown_before']).to be_nil
        end

        it 'says which earlier years the member grew it in' do
          garden = create(:garden, owner: member)
          [2023, 2024].each { |year| create(:planting, crop:, garden:, owner: member, planted_at: Date.new(year, 10, 1), finished: true) }
          get suggestions_path
          expect(crops_of(island_props).first['grown_before']).to eq 'You grew this in 2023 and 2024'
        end

        it 'does not count this year as an earlier year' do
          garden = create(:garden, owner: member)
          create(:planting, crop:, garden:, owner: member, planted_at: Date.new(2026, 10, 1))
          get suggestions_path
          expect(crops_of(island_props).first['grown_before']).to be_nil
        end

        it 'counts a variety of the crop' do
          garden = create(:garden, owner: member)
          create(:planting, crop: create(:crop, parent: crop), garden:, owner: member, planted_at: Date.new(2024, 10, 1), finished: true)
          get suggestions_path
          expect(crops_of(island_props).first['grown_before']).to eq 'You grew this in 2024'
        end

        it 'says who they follow is growing it' do
          friend = create(:member, login_name: 'sally')
          Follow.create!(follower: member, followed: friend)
          create(:planting, crop:, garden: create(:garden, owner: friend), owner: friend, planted_at: Date.new(2026, 10, 1))
          get suggestions_path
          expect(crops_of(island_props).first['followed']).to eq 'People you follow growing this: sally'
        end

        it 'says nothing of followed growers when there are none' do
          get suggestions_path
          expect(crops_of(island_props).first['followed']).to be_nil
        end

        it 'says the crop is not yet in planned jobs' do
          get suggestions_path
          expect(crops_of(island_props).first['planned']).to be false
        end

        it 'says so when the crop is already in planned jobs' do
          create(:job, owner: member, jobbable: crop, action: 'plant', name: 'Plant Wintery kale for spring 2026')
          get suggestions_path
          expect(crops_of(island_props).first['planned']).to be true
        end

        it 'leaves out a crop the member has said is not for them' do
          member.crop_dismissals.create!(crop:)
          get suggestions_path
          expect(crops_of(island_props)).to be_empty
        end

        it 'lists none when suggestions are off' do
          member.update_columns(suggest_crops: false)
          get suggestions_path
          expect(island_props['initial']).to be_empty
        end

        describe 'GET a season' do
          let(:groups) { response.parsed_body['groups'] }

          it 'answers with the crops of that season' do
            get suggestions_season_path('winter')
            expect(groups.find { |group| group['key'] == 'optimal' }['crops'].pluck('name')).to eq ['Wintery kale']
          end

          it 'names the season in the headings' do
            get suggestions_season_path('winter')
            expect(groups.find { |group| group['key'] == 'optimal' }['heading']).to eq 'Grows best in winter in Wellington'
          end

          it 'lists what gardeners nearby plant in the season' do
            neighbour = create(:garden).tap { |garden| garden.update_columns(latitude: -41.3, longitude: 174.7) }
            peas = create(:crop, name: 'Spring peas')
            create(:planting, crop: peas, garden: neighbour, owner: neighbour.owner, planted_at: Date.new(2025, 10, 5))
            get suggestions_season_path('spring')
            expect(groups.find { |group| group['key'] == 'planting' }['crops'].pluck('name')).to eq ['Spring peas']
          end

          it 'leaves out what is planted by gardeners far away' do
            far = create(:garden).tap { |garden| garden.update_columns(latitude: -37.8, longitude: 145.0) }
            create(:planting, crop: create(:crop, name: 'Far peas'), garden: far, owner: far.owner, planted_at: Date.new(2025, 10, 5))
            get suggestions_season_path('spring')
            expect(groups.find { |group| group['key'] == 'planting' }['crops']).to be_empty
          end

          it 'is not found for a season that is not one' do
            get suggestions_season_path('monsoon')
            expect(response).to have_http_status(:not_found)
          end

          it 'is not found when suggestions are off' do
            member.update_columns(suggest_crops: false)
            get suggestions_season_path('winter')
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      it 'shows it even when suggestions are off' do
        member.update_columns(suggest_crops: false)
        create(:climate_month, year: Time.zone.today.year - 1, month: 7)
        get suggestions_path
        expect(response.body).to include 'Your climate through the year'
      end
    end

    it 'shows no climate without a location' do
      get suggestions_path
      expect(response.body).not_to include 'Your climate through the year'
    end

    it 'says suggestions are off when they are' do
      member.update_columns(latitude: -41.3, longitude: 174.7, suggest_crops: false)
      get suggestions_path
      expect(response.body).to include 'Crop suggestions are off.'
    end
  end

  context 'when signed out' do
    it 'does not show the page' do
      get suggestions_path
      expect(response).to redirect_to new_member_session_path
    end
  end
end
