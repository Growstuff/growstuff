require 'rails_helper'

describe 'places/index' do
  before { render }

  it 'shows a map' do
    assert_select 'div#placesmap'
  end
end
