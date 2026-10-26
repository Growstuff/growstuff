# frozen_string_literal: true

require 'rails_helper'

describe Admin::CropJobTemplatesController do
  let(:crop) { create(:crop, name: 'tomato') }
  let(:variety) { create(:crop, name: 'cherry tomato', parent: crop) }
  let(:wrangler) { create(:crop_wrangling_member) }
  let(:step) { { name: 'Stake the plants', offset_amount: 2, offset_unit: 'weeks', direction: 'after', anchor: 'planting_out' } }

  before { sign_in wrangler }

  describe '#index' do
    let!(:for_crop) { create(:crop_job_template, crop:, name: 'For tomatoes') }
    let!(:for_variety) { create(:crop_job_template, crop: variety, name: 'For cherry') }
    let!(:for_other) { create(:crop_job_template, name: 'For something else') }

    before { get admin_crop_crop_job_templates_path(crop) }

    it 'lists the crop\'s templates' do
      expect(response.body).to include('For tomatoes')
    end

    it 'lists its varieties\' templates' do
      expect(response.body).to include('For cherry')
    end

    it 'leaves out other crops\' templates' do
      expect(response.body).not_to include('For something else')
    end
  end

  describe '#new' do
    before { get new_admin_crop_crop_job_template_path(crop) }

    it 'shows the form' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#create' do
    context 'with a name and a step' do
      before do
        post admin_crop_crop_job_templates_path(crop),
             params: { crop_job_template: { name: 'Tomato jobs', crop_id: crop.id, steps_attributes: { '0' => step } } }
      end

      it 'creates the template' do
        expect(crop.crop_job_templates.pluck(:name)).to eq ['Tomato jobs']
      end

      it 'creates its steps' do
        expect(crop.crop_job_templates.first.steps.pluck(:name)).to eq ['Stake the plants']
      end

      it 'is a draft' do
        expect(crop.crop_job_templates.first).to be_draft
      end

      it 'records who wrote it' do
        expect(crop.crop_job_templates.first.creator).to eq wrangler
      end

      it 'goes back to the list' do
        expect(response).to redirect_to(admin_crop_crop_job_templates_path(crop))
      end
    end

    context 'with a step that has a link' do
      before do
        post admin_crop_crop_job_templates_path(crop),
             params: { crop_job_template: { name: 'Tomato jobs', steps_attributes: { '0' => step.merge(external_uri: 'https://example.com/staking') } } }
      end

      it 'saves the link' do
        expect(crop.crop_job_templates.first.steps.first.external_uri).to eq 'https://example.com/staking'
      end
    end

    context 'with a step whose link is not a web address' do
      before do
        post admin_crop_crop_job_templates_path(crop),
             params: { crop_job_template: { name: 'Tomato jobs', steps_attributes: { '0' => step.merge(external_uri: 'example.com') } } }
      end

      it 'shows the form again' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'creates nothing' do
        expect(CropJobTemplate.count).to eq 0
      end
    end

    context 'when for one of the crop\'s varieties' do
      before { post admin_crop_crop_job_templates_path(crop), params: { crop_job_template: { name: 'Cherry jobs', crop_id: variety.id } } }

      it 'is for that variety' do
        expect(CropJobTemplate.find_by(name: 'Cherry jobs').crop).to eq variety
      end
    end

    context 'when for another crop' do
      before do
        post admin_crop_crop_job_templates_path(crop), params: { crop_job_template: { name: 'Sneaky', crop_id: create(:crop).id } }
      end

      it 'is for this crop instead' do
        expect(CropJobTemplate.find_by(name: 'Sneaky').crop).to eq crop
      end
    end

    context 'without a name' do
      before { post admin_crop_crop_job_templates_path(crop), params: { crop_job_template: { name: '' } } }

      it 'shows the form again' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'creates nothing' do
        expect(CropJobTemplate.count).to eq 0
      end
    end

    context 'when adding a step' do
      before do
        post admin_crop_crop_job_templates_path(crop), params: { commit: 'add_step', crop_job_template: { name: 'Half done' } }
      end

      it 'saves nothing' do
        expect(CropJobTemplate.count).to eq 0
      end

      it 'shows the form again' do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '#edit' do
    let(:template) { create(:crop_job_template, crop:) }

    before do
      create(:crop_job_step, crop_job_template: template, name: 'Stake', external_uri: 'https://example.com/staking')
      get edit_admin_crop_crop_job_template_path(crop, template), params: { planting_out_on: '2026-12-01' }
    end

    it 'shows the form' do
      expect(response).to have_http_status(:ok)
    end

    it 'links a step with an address to it, in the preview' do
      expect(Capybara.string(response.body)).to have_link('More info', href: 'https://example.com/staking')
    end
  end

  describe '#update' do
    let(:template) { create(:crop_job_template, crop:, name: 'Before') }
    let!(:existing_step) { create(:crop_job_step, crop_job_template: template, name: 'Old step') }

    context 'with new settings and a changed step' do
      before do
        patch admin_crop_crop_job_template_path(crop, template),
              params: { crop_job_template: { name: 'After', status: 'published',
                                             steps_attributes: { '0' => { id: existing_step.id, name: 'New step' } } } }
      end

      it 'saves the template' do
        expect(template.reload).to have_attributes(name: 'After', status: 'published')
      end

      it 'saves the step' do
        expect(existing_step.reload.name).to eq 'New step'
      end
    end

    context 'when removing a step' do
      before do
        patch admin_crop_crop_job_template_path(crop, template),
              params: { crop_job_template: { steps_attributes: { '0' => { id: existing_step.id, _destroy: '1' } } } }
      end

      it 'deletes the step' do
        expect(template.steps.count).to eq 0
      end
    end

    context 'without a name' do
      before { patch admin_crop_crop_job_template_path(crop, template), params: { crop_job_template: { name: '' } } }

      it 'shows the form again' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe '#destroy' do
    let!(:template) { create(:crop_job_template, crop:) }

    it 'deletes the template' do
      expect { delete admin_crop_crop_job_template_path(crop, template) }.to change(CropJobTemplate, :count).by(-1)
    end
  end

  context 'when not a crop wrangler' do
    before do
      sign_out wrangler
      sign_in create(:member)
      get admin_crop_crop_job_templates_path(crop)
    end

    it 'is turned away' do
      expect(response).to redirect_to(root_path)
    end
  end
end
