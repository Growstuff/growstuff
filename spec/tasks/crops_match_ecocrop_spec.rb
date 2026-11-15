# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'crops:match_ecocrop' do # rubocop:disable RSpec/DescribeClass
  let(:review_path) { Rails.root.join('tmp/ecocrop_review_spec.csv').to_s }
  let!(:cucumber) { create(:ecocrop_data, scientificname: 'Cucumis sativus') }
  let!(:crop) { create(:crop, name: 'cucumber') }

  before do
    Rails.application.load_tasks
    create(:scientific_name, crop:, name: 'Cucumis sativus')
    ENV['REVIEW_CSV'] = review_path
    ENV.delete('DRY_RUN')
  end

  after do
    ENV.delete('REVIEW_CSV')
    ENV.delete('DRY_RUN')
    FileUtils.rm_f(review_path)
    Rake::Task['crops:match_ecocrop'].reenable
  end

  def invoke
    expect { Rake::Task['crops:match_ecocrop'].invoke }.to output.to_stdout
  end

  it 'links a sure match' do
    expect { invoke }.to change { crop.reload.ecocrop_data_id }.to(cucumber.id)
  end

  it 'links nothing on a dry run' do
    ENV['DRY_RUN'] = 'true'
    expect { invoke }.not_to(change { crop.reload.ecocrop_data_id })
  end
end
