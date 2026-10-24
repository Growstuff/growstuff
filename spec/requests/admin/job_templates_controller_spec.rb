# frozen_string_literal: true

require 'rails_helper'

describe Admin::JobTemplatesController do
  let(:tomato) { create(:crop, name: 'tomato') }
  let(:cherry) { create(:crop, name: 'cherry tomato', parent: tomato) }
  let(:author) { create(:member, login_name: 'template_author') }

  before do
    create(:crop_job_template, crop: tomato, name: 'Growing tomatoes', status: 'published', creator: author)
    create(:crop_job_template, crop: cherry, name: 'Growing cherry tomatoes')
    create(:crop_job_template, name: 'Growing something else')
  end

  describe '#index' do
    context 'with a crop wrangler' do
      before { sign_in create(:crop_wrangling_member) }

      context 'without a status' do
        before { get admin_job_templates_path }

        it 'lists every crop\'s templates' do
          expect(response.body).to include('Growing tomatoes', 'Growing cherry tomatoes', 'Growing something else')
        end

        it 'shows who wrote a template' do
          expect(response.body).to include('template_author')
        end

        it 'links a variety\'s template to its parent crop\'s templates' do
          expect(response.body).to include(edit_admin_crop_crop_job_template_path(tomato, cherry.crop_job_templates.first))
        end
      end

      context 'when filtered to published' do
        before { get admin_job_templates_path(status: 'published') }

        it 'lists the published templates' do
          expect(response.body).to include('Growing tomatoes')
        end

        it 'leaves out the drafts' do
          expect(response.body).not_to include('Growing cherry tomatoes')
        end
      end

      context 'when filtered to draft' do
        before { get admin_job_templates_path(status: 'draft') }

        it 'lists the drafts' do
          expect(response.body).to include('Growing cherry tomatoes', 'Growing something else')
        end

        it 'leaves out the published templates' do
          expect(response.body).not_to include('Growing tomatoes')
        end
      end

      context 'with an unknown status' do
        before { get admin_job_templates_path(status: 'nonsense') }

        it 'lists every template' do
          expect(response.body).to include('Growing tomatoes', 'Growing cherry tomatoes')
        end
      end
    end

    context 'when not a crop wrangler' do
      before do
        sign_in create(:member)
        get admin_job_templates_path
      end

      it 'is turned away' do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
