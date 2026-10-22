# frozen_string_literal: true

require 'rails_helper'

describe CropsController, '#wrangle' do
  let!(:tomato) { create(:crop, name: 'tomato') }
  let!(:cherry) { create(:crop, name: 'cherry tomato', parent: tomato) }
  let!(:apple) { create(:crop, name: 'Apple') }

  before { sign_in create(:crop_wrangling_member) }

  context 'by default' do
    before { get wrangle_crops_path }

    it 'lists crops with no parent' do
      expect(response.body).to include('tomato', 'Apple')
    end

    it 'leaves out crops with a parent' do
      expect(response.body).not_to include('cherry tomato')
    end

    it 'sorts by name, ignoring case' do
      expect(response.body.index('Apple')).to be < response.body.index('tomato')
    end
  end

  context 'with job templates' do
    before do
      create_list(:crop_job_template, 2, crop: tomato)
      get wrangle_crops_path
    end

    it 'links a crop to its job templates, with how many' do
      expect(Capybara.string(response.body)).to have_link('2 templates', href: admin_crop_crop_job_templates_path(tomato))
    end

    it 'offers to add one to a crop with none' do
      expect(Capybara.string(response.body)).to have_link('Add', href: new_admin_crop_crop_job_template_path(apple))
    end
  end

  context 'when showing all crops' do
    before { get wrangle_crops_path(level: 'all') }

    it 'includes crops with a parent' do
      expect(response.body).to include('cherry tomato')
    end
  end

  context 'with pending crops' do
    let!(:pending) { create(:crop_request, name: 'mystery seedling') }

    before { get wrangle_crops_path(approval_status: 'pending') }

    it 'lists them' do
      expect(response.body).to include('mystery seedling')
    end

    it 'leaves out approved crops' do
      expect(response.body).not_to include('Apple')
    end
  end

  context 'when searching' do
    let!(:other_variety) { create(:crop, name: 'beefsteak', parent: tomato) }
    let!(:pending) { create(:crop_request, name: 'purple tomato') }

    before { get wrangle_crops_path(q: 'tomato') }

    it 'finds the crop' do
      expect(Capybara.string(response.body)).to have_link('tomato', href: edit_crop_path(tomato))
    end

    it 'finds its varieties, though they have a parent' do
      expect(response.body).to include('cherry tomato')
    end

    it 'leaves out crops that do not match' do
      expect(response.body).not_to include('Apple')
    end

    it 'leaves out pending crops on the approved tab' do
      expect(response.body).not_to include('purple tomato')
    end

    it 'puts the crop named exactly the term first' do
      expect(response.body.index(edit_crop_path(tomato))).to be < response.body.index(edit_crop_path(cherry))
    end

    it 'finds a crop by its scientific name' do
      create(:scientific_name, crop: apple, name: 'Malus domestica')
      get wrangle_crops_path(q: 'malus')
      expect(response.body).to include('Apple')
    end
  end

  context 'when searching pending crops' do
    let!(:pending) { create(:crop_request, name: 'purple tomato') }

    before { get wrangle_crops_path(q: 'tomato', approval_status: 'pending') }

    it 'finds the pending crop' do
      expect(response.body).to include('purple tomato')
    end
  end
end
