# frozen_string_literal: true

require 'rails_helper'

describe 'jobs/_notepad_row' do
  let(:job) { create(:job, name: 'Net the berries') }

  before do
    allow(view).to receive(:can?).and_return(true)
    render partial: 'jobs/notepad_row', locals: { job: }
  end

  it 'shows the name' do
    expect(rendered).to have_css('.notepad-name', text: 'Net the berries')
  end

  it 'has a menu Edit that the script edits in place' do
    expect(rendered).to have_css('a[data-notepad-edit]', text: 'Edit', visible: :all)
  end

  it 'still has the form page for Edit, when the script cannot' do
    expect(rendered).to have_link('Edit', href: edit_job_path(job), visible: :all)
  end

  context 'when crossed off' do
    let(:job) { create(:job, due_date: Date.new(2020, 1, 6), finished: true) }

    it 'shows when it was crossed off, not when it was due' do
      expect(rendered).to have_css('.notepad-due', text: /\Adone /)
    end
  end

  it 'has no Mark as finished in its menu, as it has a tick box' do
    expect(rendered).to have_no_link('Mark as finished', visible: :all)
  end

  it 'has a hint for editing, hidden until then' do
    expect(rendered).to have_css('.notepad-edit-hint[hidden]', text: 'Enter to save', visible: :all)
  end
end
