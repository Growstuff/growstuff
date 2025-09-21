require 'rails_helper'

RSpec.describe Activity, type: :model do
  it { should belong_to(:garden).optional }
  it { should belong_to(:planting).optional }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:category) }
  it { should validate_inclusion_of(:category).in_array(Activity::CATEGORIES) }
  it { should validate_presence_of(:owner) }

  it 'has a valid factory' do
    expect(build(:activity)).to be_valid
  end

end
