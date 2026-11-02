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

    it 'loads the garden\'s collaborators with the jobs, for the permission checks' do
      job = notepad.groups.flat_map(&:jobs).first
      expect(job.garden.association(:garden_collaborators)).to be_loaded
    end

    it 'has the member\'s jobs for it' do
      expect(names).to eq ['Net the berries']
    end

    it 'includes a collaborator\'s job in the garden' do
      collaborator = create(:member)
      create(:garden_collaborator, garden: berries, member: collaborator)
      create(:job, owner: collaborator, garden: berries, name: 'A collaborator\'s job', due_date: Time.zone.today)
      expect(names).to contain_exactly('Net the berries', 'A collaborator\'s job')
    end

    it 'leaves out jobs for other gardens' do
      other_garden = create(:garden, owner: member)
      create(:job, owner: member, garden: other_garden, name: 'Water the plot', due_date: Time.zone.today)
      expect(names).to eq ['Net the berries']
    end
  end

  context 'when the member is a garden collaborator' do
    let(:community_garden) { create(:garden) }
    let!(:collab_job) { create(:job, garden: community_garden, name: 'Weed community plot', due_date: Time.zone.today) }

    before do
      create(:garden_collaborator, garden: community_garden, member:)
    end

    it 'includes jobs for the collaborated garden' do
      expect(names).to include('Weed community plot')
    end

    it 'includes jobs for plantings in the collaborated garden' do
      planting = create(:planting, garden: community_garden, owner: community_garden.owner)
      create(:job, jobbable: planting, name: 'Stake shared tomatoes', due_date: Time.zone.today)
      expect(names).to include('Stake shared tomatoes')
    end

    it 'leaves out jobs from unrelated gardens' do
      unrelated_garden = create(:garden)
      create(:job, garden: unrelated_garden, name: 'Unrelated job', due_date: Time.zone.today)
      expect(names).not_to include('Unrelated job')
    end
  end

  context 'without a member' do
    subject(:notepad) { described_class.new(nil, garden: berries) }

    it 'has everyone\'s jobs for the garden' do
      create(:job, garden: berries, name: 'A collaborator\'s job', due_date: Time.zone.today)
      expect(names).to contain_exactly('Net the berries', 'A collaborator\'s job')
    end

    it 'leaves out jobs for other gardens' do
      expect(names).not_to include('Sharpen the secateurs')
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
