# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'import:ecocrop_data' do # rubocop:disable RSpec/DescribeClass
  before do
    Rails.application.load_tasks
  end

  it 'imports ecocrop data from the parquet file and is idempotent' do
    Rake::Task['import:ecocrop_data'].invoke

    expect(EcocropData.count).to be_positive

    record = EcocropData.by_scientific_name('Abelmoschus esculentus')
    expect(record).to be_present
    expect(record.ecoportcode).to eq(289)
    expect(record.topmn).to eq(20)
    expect(record.topmx).to eq(30)

    initial_count = EcocropData.count

    # Test idempotency
    Rake::Task['import:ecocrop_data'].reenable
    Rake::Task['import:ecocrop_data'].invoke
    expect(EcocropData.count).to eq(initial_count)
  end
end
