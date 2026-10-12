# frozen_string_literal: true

require 'rails_helper'

# Which link in the top menu gets the orange underline.
describe ApplicationHelper do
  describe '#current_section?' do
    def on(path)
      allow(helper.request).to receive(:path).and_return(path)
    end

    it 'is true on the page itself' do
      on '/crops'
      expect(helper.current_section?('/crops')).to be true
    end

    it 'is true on a page under it' do
      on '/crops/basil'
      expect(helper.current_section?('/crops')).to be true
    end

    it 'is false on a different section' do
      on '/seeds'
      expect(helper.current_section?('/crops')).to be false
    end

    it 'is not fooled by a path that only starts the same' do
      on '/cropsy'
      expect(helper.current_section?('/crops')).to be false
    end

    it 'ignores an anchor on the path it is given' do
      on '/members/sam/gardens'
      expect(helper.current_section?('/members/sam/gardens#content')).to be true
    end

    it 'is true if any of several paths match' do
      on '/forums'
      expect(helper.current_section?('/posts', '/forums')).to be true
    end
  end
end
