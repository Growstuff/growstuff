# frozen_string_literal: true

require 'rails_helper'

describe 'likes/_description' do
  let(:job) { create(:job) }
  let(:like) { create(:like, likeable: job) }

  before { render partial: 'likes/description', locals: { event_model: like } }

  it 'links a liked job to its owner\'s jobs, as a job has no page of its own' do
    expect(rendered).to have_link('job', href: member_jobs_path(job.owner))
  end
end
