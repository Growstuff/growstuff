# frozen_string_literal: true

require 'rails_helper'

describe JobsNotepad do
  subject(:notepad) { described_class.new(member, garden:, pinned:) }

  let(:member) { create(:member) }
  let(:garden) { nil }
  let(:pinned) { [] }
  let(:berries) { create(:garden, owner: member) }
  let!(:in_berries) { create(:job, owner: member, garden: berries, name: 'Net the berries', due_date: Time.zone.today) }
  let!(:elsewhere) { create(:job, owner: member, name: 'Sharpen the secateurs', due_date: Time.zone.today) }

  def names
    notepad.groups.flat_map(&:jobs).map(&:name)
  end

  it 'has the member\'s jobs' do
    expect(names).to contain_exactly('Net the berries', 'Sharpen the secateurs')
  end

  it 'leaves out other members\' jobs' do
    create(:job, name: 'Someone else\'s')
    expect(names).not_to include('Someone else\'s')
  end

  context 'with a garden' do
    let(:garden) { berries }

    it 'has only the member\'s jobs for it' do
      expect(names).to eq ['Net the berries']
    end

    it 'leaves out other members\' jobs for it, though they are in it' do
      create(:job, garden: berries, name: 'A collaborator\'s job')
      expect(names).to eq ['Net the berries']
    end
  end

  describe '#done_this_week' do
    it 'counts the jobs crossed off this week' do
      in_berries.update!(finished: true)
      expect(notepad.done_this_week).to eq 1
    end

    context 'with a garden' do
      let(:garden) { berries }

      it 'counts only the jobs for it' do
        elsewhere.update!(finished: true)
        expect(notepad.done_this_week).to eq 0
      end
    end
  end

  context 'with a job crossed off in the page being looked at' do
    let(:pinned) { [in_berries.id] }

    before { in_berries.update!(finished: true, due_date: Time.zone.today - 3.days) }

    it 'keeps it where its day puts it, not in Done' do
      expect(notepad.groups.find { |group| group.key == :overdue }.jobs).to eq [in_berries]
    end
  end
end
