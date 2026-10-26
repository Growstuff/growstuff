# frozen_string_literal: true

require 'rails_helper'

# What a record may be linked to: gardens are the writer's to put things in, and a job is only about the writer's own things.
RSpec.describe 'API linking records' do
  include_context 'with an API member'

  let(:other_member) { create(:member) }
  let(:own_garden) { create(:garden, owner: member) }
  let(:their_garden) { create(:garden, owner: other_member) }
  let(:crop) { create(:crop) }

  def post_planting(garden)
    post '/api/v1/plantings',
         params:  { data: { type:          'plantings',
                            relationships: { crop: link_to('crops', crop.id), garden: link_to('gardens', garden.id) } } }.to_json,
         headers: auth_headers
  end

  def post_job(attributes: {}, relationships: {})
    data = { type: 'jobs', attributes: { name: 'Water' }.merge(attributes), relationships: relationships }
    post '/api/v1/jobs', params: { data: }.to_json, headers: auth_headers
  end

  describe 'planting in your own garden' do
    before { post_planting(own_garden) }

    it { expect(response).to have_http_status(:created) }
  end

  describe 'planting in someone else\'s garden' do
    before { post_planting(their_garden) }

    it { expect(response).to have_http_status(:forbidden) }

    it 'plants nothing' do
      expect(their_garden.plantings).to be_empty
    end
  end

  describe 'planting in a garden you only collaborate on' do
    before do
      create(:garden_collaborator, garden: their_garden, member: member)
      post_planting(their_garden)
    end

    it { expect(response).to have_http_status(:forbidden) }
  end

  describe 'moving your planting into someone else\'s garden' do
    let(:planting) { create(:planting, owner: member, garden: own_garden) }

    before do
      create(:garden_collaborator, garden: their_garden, member: member)
      patch "/api/v1/plantings/#{planting.id}",
            params:  { data: { type: 'plantings', id: planting.id.to_s,
relationships: { garden: link_to('gardens', their_garden.id) } } }.to_json,
            headers: auth_headers
    end

    it { expect(response).to have_http_status(:forbidden) }

    it 'leaves it where it was' do
      expect(planting.reload.garden).to eq(own_garden)
    end
  end

  describe 'changing a planting in a garden you collaborate on' do
    let(:planting) { create(:planting, owner: other_member, garden: their_garden) }

    before do
      create(:garden_collaborator, garden: their_garden, member: member)
      patch "/api/v1/plantings/#{planting.id}",
            params:  { data: { type: 'plantings', id: planting.id.to_s, attributes: { description: 'Doing well' } } }.to_json,
            headers: auth_headers
    end

    it { expect(response).to have_http_status(:ok) }
  end

  describe 'a job in your own garden' do
    before { post_job(relationships: { garden: link_to('gardens', own_garden.id) }) }

    it { expect(response).to have_http_status(:created) }
  end

  describe 'a job in someone else\'s garden' do
    before { post_job(relationships: { garden: link_to('gardens', their_garden.id) }) }

    it { expect(response).to have_http_status(:forbidden) }

    it 'adds no job to their garden' do
      expect(their_garden.jobs).to be_empty
    end
  end

  describe 'a job about one of your plantings' do
    let(:planting) { create(:planting, owner: member, garden: own_garden) }

    before { post_job(attributes: { 'jobbable-type' => 'Planting', 'jobbable-id' => planting.id }) }

    it { expect(response).to have_http_status(:created) }
  end

  describe 'a job about someone else\'s planting' do
    let(:planting) { create(:planting, owner: other_member, garden: their_garden) }

    before { post_job(attributes: { 'jobbable-type' => 'Planting', 'jobbable-id' => planting.id }) }

    it { expect(response).to have_http_status(:unprocessable_entity) }

    it 'makes no job' do
      expect(Job.where(owner: member, name: 'Water')).to be_empty
    end
  end

  describe 'a job about someone else\'s seed' do
    let(:seed) { create(:seed, owner: other_member) }

    before { post_job(attributes: { 'jobbable-type' => 'Seed', 'jobbable-id' => seed.id }) }

    it { expect(response).to have_http_status(:unprocessable_entity) }
  end

  describe 'a job about something that is not a crop, planting or seed' do
    before { post_job(attributes: { 'jobbable-type' => 'Member', 'jobbable-id' => other_member.id }) }

    it { expect(response).to have_http_status(:unprocessable_entity) }
  end

  describe 'a job about a kind of record that does not exist' do
    before { post_job(attributes: { 'jobbable-type' => 'Nonsense', 'jobbable-id' => 1 }) }

    it { expect(response).to have_http_status(:unprocessable_entity) }
  end

  describe 'a job about a record that does not exist' do
    before { post_job(attributes: { 'jobbable-type' => 'Planting', 'jobbable-id' => 0 }) }

    it { expect(response).to have_http_status(:unprocessable_entity) }
  end

  describe 'a job with an action that does not fit what it is about' do
    before do
      post_job(attributes: { 'action' => 'plant', 'jobbable-type' => 'Planting',
     'jobbable-id' => create(:planting, owner: member, garden: own_garden).id })
    end

    it { expect(response).to have_http_status(:unprocessable_entity) }
  end

  describe 'a job with an action that does not exist' do
    before { post_job(attributes: { 'action' => 'nonsense' }) }

    it { expect(response).to have_http_status(:unprocessable_entity) }
  end
end
