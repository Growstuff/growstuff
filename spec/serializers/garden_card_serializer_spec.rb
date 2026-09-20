# frozen_string_literal: true

require 'rails_helper'

describe GardenCardSerializer do
  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:garden) { create(:garden, owner: member, name: 'Back garden') }
  let(:annual_crop) { create(:annual_crop, name: 'lettuce') }
  let(:perennial_crop) { create(:perennial_crop, name: 'rosemary') }

  def serialize(garden, viewer: member, **)
    described_class.collection([garden], ability: Ability.new(viewer), **).first
  end

  describe 'the garden' do
    subject(:card) { serialize(garden) }

    it 'has its basic details and links' do
      expect(card).to include(id: garden.id, name: 'Back garden', slug: garden.slug, active: true,
                              url: "/gardens/#{garden.slug}", can_edit: true)
    end

    it 'uses the placeholder image when there is no photo' do
      expect(card[:image_url]).to match(%r{\A/assets/placeholder_600.*\.png\z})
    end

    it 'shows its owner, unless asked not to' do
      expect(card[:owner]).to eq(login_name: member.login_name, url: "/members/#{member.slug}")
      expect(serialize(garden, show_owner: false)[:owner]).to be_nil
    end
  end

  describe 'garden actions' do
    it 'gives the owner of an active garden the menu of gardens/_actions, in order, without the Add planting button' do
      actions = serialize(garden)[:actions]

      expect(actions.pluck(:key)).to eq %i(plan deactivate edit photo delete)
    end

    it 'links the Add planting button to the new planting form for an active garden you can edit' do
      expect(serialize(garden)[:plant_url]).to eq "/plantings/new?garden_id=#{garden.id}"
    end

    it 'has no Add planting link for an inactive garden, or one that is not yours' do
      garden.update!(active: false)

      expect(serialize(garden)[:plant_url]).to be_nil
      expect(serialize(create(:garden), viewer: member)[:plant_url]).to be_nil
    end

    it 'marks deactivating and deleting as non-GET links that ask for confirmation' do
      actions = serialize(garden)[:actions].index_by { |action| action[:key] }

      expect(actions[:deactivate]).to include(method: :put, confirm: I18n.t('gardens.confirm_deactivate'))
      expect(actions[:delete]).to include(method: :delete, confirm: I18n.t('gardens.confirm_delete'), divider: true)
      expect(actions[:edit]).not_to have_key(:method)
    end

    it 'offers only activate, edit, photo and delete for an inactive garden' do
      garden.update!(active: false)

      actions = serialize(garden)[:actions]

      expect(actions.pluck(:key)).to eq %i(activate edit photo delete)
      expect(actions.first).to include(method: :put)
    end

    it 'offers nothing to someone who cannot edit the garden' do
      card = serialize(garden, viewer: other_member)

      expect(card[:can_edit]).to be false
      expect(card[:actions]).to eq []
    end

    it 'offers nothing to a visitor who is not signed in' do
      expect(serialize(garden, viewer: nil)[:actions]).to eq []
    end
  end

  describe 'plantings' do
    let!(:annual) { create(:planting, garden: garden, owner: member, crop: annual_crop, planted_at: 10.days.ago) }
    let!(:perennial) { create(:planting, garden: garden, owner: member, crop: perennial_crop) }

    it 'splits active plantings into perennials and annuals' do
      card = serialize(garden)

      expect(card[:perennials].pluck(:id)).to eq [perennial.id]
      expect(card[:annuals].pluck(:id)).to eq [annual.id]
    end

    it 'leaves out finished and failed plantings' do
      create(:finished_planting, garden: garden, owner: member, crop: annual_crop)
      create(:planting, garden: garden, owner: member, crop: annual_crop, failed: true)

      expect(serialize(garden)[:annuals].pluck(:id)).to eq [annual.id]
    end

    it 'includes the crop and a link for each planting' do
      planting = serialize(garden)[:annuals].first

      expect(planting).to include(url: "/plantings/#{annual.slug}", crop: { name: 'lettuce', icon_url: nil })
    end

    it 'says how the planting is getting on, for the progress bar colour' do
      expect(serialize(garden)[:annuals].first[:progress_state]).to eq :growing
    end

    it 'says why there is no progress bar' do
      annual.update!(planted_at: nil)

      expect(serialize(garden)[:annuals].first[:progress_note]).to eq 'Set a planted date to see predictions'
    end

    it 'gives the owner the quick actions from plantings/_quick_actions' do
      actions = serialize(garden)[:annuals].first[:actions]

      expect(actions.pluck(:key)).to eq %i(view edit photo finish harvest seeds)
      expect(actions.find { |action| action[:key] == :finish }).to include(method: :put)
    end

    it 'gives someone else no planting actions' do
      expect(serialize(garden, viewer: other_member)[:annuals].first[:actions]).to eq []
    end

    it 'says whether the viewer can edit the planting, so its date can be changed' do
      expect(serialize(garden)[:annuals].first[:can_edit]).to be true
      expect(serialize(garden, viewer: other_member)[:annuals].first[:can_edit]).to be false
    end
  end

  describe 'labels' do
    it 'are all real translations, never a missing-translation placeholder' do
      create(:planting, garden: garden, owner: member, crop: annual_crop, planted_at: 10.days.ago)
      create(:planting, garden: garden, owner: member, crop: perennial_crop)

      card = serialize(garden)
      labels = (card[:actions] + card[:annuals].flat_map { |planting| planting[:actions] + planting[:badges] })
        .flat_map { |item| [item[:label], item[:confirm]] }.compact

      expect(labels).to include('View', 'Edit', 'Add photo')
      expect(labels).to all(satisfy { |label| label.exclude?('translation missing') && label.exclude?('Translation missing') })
    end
  end

  describe '.collection' do
    it 'loads the plantings for every garden in one query' do
      gardens = create_list(:garden, 3, owner: member)
      gardens.each { |g| create_list(:planting, 2, garden: g, owner: member, crop: annual_crop) }

      planting_queries = []
      callback = ->(*, payload) { planting_queries << payload[:sql] if payload[:sql].match?(/FROM "plantings"/) }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        described_class.collection(gardens, ability: Ability.new(member))
      end

      expect(planting_queries.size).to eq 1
    end

    it 'returns a card for a garden with no plantings' do
      card = serialize(garden)

      expect(card).to include(perennials: [], annuals: [])
    end
  end
end
