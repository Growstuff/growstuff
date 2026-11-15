# frozen_string_literal: true

require 'rails_helper'

describe WeatherInvitationHelper do
  let(:invitation) { instance_double(WeatherInvitation, state:, place_name: 'Wellington', frost: nil, climate:) }
  let(:climate) { nil }
  let(:cards) { helper.weather_invitation_cards(invitation) }

  context 'without a location' do
    let(:state) { :no_location }

    it 'has frost, rain and temperature cards' do
      expect(cards.pluck(:measure)).to eq %i(frost rain air)
    end

    it 'says what they would get' do
      expect(cards.first[:title]).to eq 'When frost danger starts and ends'
    end
  end

  context 'when the weather is loading' do
    let(:state) { :loading }

    it 'says it is not ready' do
      expect(cards.pluck(:title).uniq).to eq ['Not ready yet']
    end

    it 'names the place in the sentence' do
      expect(helper.weather_invitation_intro(invitation)).to include 'Wellington'
    end
  end

  context 'when only the frost is ready' do
    let(:state) { :ready }
    let(:frost) { instance_double(FrostSeason, verdict: :rare) }
    let(:invitation) { instance_double(WeatherInvitation, state:, place_name: 'Wellington', frost:, climate:) }

    it 'headlines the frost' do
      expect(cards.first[:note]).to eq 'Frost is rare here'
    end

    it 'leaves the rain loading' do
      expect(cards.second[:title]).to eq 'Not ready yet'
    end
  end

  context 'when the rain is wetter than usual' do
    let(:state) { :ready }
    let(:climate) { instance_double(PlaceClimate, rain_comparison: :wetter, rain_share: 1.17, air_comparison: nil) }

    it 'headlines the rain' do
      expect(cards.second.slice(:title, :note)).to eq(title: 'Wetter than usual this year', note: '117% of the usual by this date')
    end
  end

  context 'when the air is a little warmer than usual' do
    let(:state) { :ready }
    let(:climate) { instance_double(PlaceClimate, rain_comparison: nil, air_comparison: :a_little_warmer, air_difference: 0.4) }

    it 'headlines the temperature' do
      expect(cards.third.slice(:title, :note)).to eq(title: 'A little warmer than usual', note: '0.4 °C above the usual this year')
    end
  end
end
