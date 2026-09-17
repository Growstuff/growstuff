# frozen_string_literal: true

require 'rails_helper'

describe "crops/_grown_for" do
  let(:crop)       { create(:crop)       }
  let(:plant_path) { create(:plant_part) }
  let!(:harvest) do
    create(:harvest,
           crop:,
           plant_part: plant_path)
  end

  it 'shows plant parts' do
    render partial: 'crops/grown_for', locals: { crop: }
    expect(rendered).to have_content plant_path.name
    assert_select "a", href: plant_part_path(plant_path)
  end
end
