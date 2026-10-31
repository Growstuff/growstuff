# frozen_string_literal: true

require 'rails_helper'

describe 'jobs/_notepad' do
  let(:owner) { create(:member) }

  context 'when it is the main jobs page' do
    before { render partial: 'jobs/notepad', locals: { owner:, groups: [], done_this_week: 2 } }

    it 'says how many jobs are done this week' do
      expect(rendered).to have_css('#notepad-snail-caption', text: 'Slow and steady. 2 jobs done this week.')
    end

    it 'leaves that line for screen readers, hiding only the snail\'s picture' do
      expect(rendered).to have_xpath("//*[@id='notepad-snail-caption'][not(ancestor-or-self::*[@aria-hidden='true'])]")
    end

    it 'hides the picture of the snail from screen readers' do
      expect(rendered).to have_css('.notepad-snail-track[aria-hidden="true"]')
    end
  end

  context 'when it is on a garden page' do
    let(:garden) { create(:garden, owner:) }

    before { render partial: 'jobs/notepad', locals: { owner:, garden:, groups: [] } }

    it 'leaves out the snail' do
      expect(rendered).to have_no_css('.notepad-snail')
    end

    it 'still has the list of jobs' do
      expect(rendered).to have_css('#notepad-groups')
    end
  end
end
