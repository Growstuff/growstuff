# frozen_string_literal: true

require 'rails_helper'

describe 'jobs/_notepad' do
  let(:owner) { create(:member) }

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
