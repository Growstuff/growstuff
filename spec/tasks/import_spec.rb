require 'rails_helper'
require 'rake'

describe 'import:australian_food_classification_data' do
  before :all do
    Rails.application.load_tasks
  end

  it "imports the data from the CSV file" do
    Rake::Task['import:australian_food_classification_data'].invoke
    expect(AustralianFoodClassificationData.count).to eq(2)

    first_record = AustralianFoodClassificationData.find_by(public_food_key: 'F002258')
    expect(first_record.food_name).to eq('Cardamom seed, dried, ground')
    expect(first_record.protein_g).to eq(BigDecimal('10.8'))

    second_record = AustralianFoodClassificationData.find_by(public_food_key: 'F002893')
    expect(second_record.food_name).to eq('Chilli (chili), dried, ground')
    expect(second_record.fat_total_g).to eq(BigDecimal('14.3'))

    # Test idempotency
    Rake::Task['import:australian_food_classification_data'].reenable
    Rake::Task['import:australian_food_classification_data'].invoke
    expect(AustralianFoodClassificationData.count).to eq(2)
  end
end
