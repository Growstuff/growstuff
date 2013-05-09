require 'spec_helper'

describe Photo do

  describe 'flickr_metadata' do
    # Any further tests led to us MOCKING ALL THE THINGS
    # which was epistemologically unsatisfactory.
    # So we're just going to test that the method exists.
    it 'exists' do
      photo = Photo.new(:owner_id => 1)
      photo.should.respond_to? :flickr_metadata
    end
  end
end
