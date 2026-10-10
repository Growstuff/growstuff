# frozen_string_literal: true

require 'rails_helper'

describe CropIconMatcher do
  describe '.icon_for' do
    it 'knows crops by name, whatever the case, singular or plural' do
      expect(described_class.icon_for('Tomato')).to eq 'tomato'
      expect(described_class.icon_for('strawberries')).to eq 'strawberry'
    end

    it 'knows the other names a crop goes by' do
      expect(described_class.icon_for('aubergine')).to eq 'eggplant'
      expect(described_class.icon_for('capsicum')).to eq 'bell_pepper'
      expect(described_class.icon_for('basil')).to eq 'herb'
    end

    it 'has nothing for a crop without an icon' do
      expect(described_class.icon_for('fig')).to be_nil
    end
  end

  describe '.icon_for_last_words' do
    it 'goes by the end of the name, longest first' do
      expect(described_class.icon_for_last_words('cherry tomato')).to eq 'tomato'
      expect(described_class.icon_for_last_words('flat leaf parsley')).to eq 'herb'
      expect(described_class.icon_for_last_words('rocket potato')).to eq 'potato'
    end

    it "doesn't make a named chilli a bell pepper" do
      expect(described_class.icon_for_last_words('habanero pepper')).to eq 'hot_pepper'
      expect(described_class.icon_for_last_words('sweet pepper')).to eq 'bell_pepper'
    end
  end

  it 'names only icons the app has' do
    expect(described_class::MATCHES.keys - Crop.icon_names).to be_empty
  end

  describe '#call' do
    it 'gives crops their icon, and says which' do
      tomato = create(:crop, name: 'tomato')
      fig = create(:crop, name: 'fig')

      expect(described_class.new.call).to eq(tomato => 'tomato')
      expect(tomato.reload.icon).to eq 'tomato'
      expect(fig.reload.icon).to be_nil
    end

    it 'matches a crop with no parent by the end of its name' do
      cherry = create(:crop, name: 'cherry tomato')
      described_class.new.call

      expect(cherry.reload.icon).to eq 'tomato'
    end

    # A variety that has a parent follows its icon, rather than getting its own.
    it 'leaves a variety to follow its parent' do
      tomato = create(:crop, name: 'tomato')
      cherry = create(:crop, name: 'cherry tomato', parent: tomato)
      described_class.new.call

      expect(cherry.reload.icon).to be_nil
      expect(cherry.svg_icon).to eq tomato.reload.svg_icon
    end

    it "never replaces an icon someone chose" do
      tomato = create(:crop, name: 'tomato', icon: 'cherries')
      described_class.new.call

      expect(tomato.reload.icon).to eq 'cherries'
    end

    it 'changes nothing on a dry run' do
      tomato = create(:crop, name: 'tomato')

      expect(described_class.new.call(dry_run: true)).to eq(tomato => 'tomato')
      expect(tomato.reload.icon).to be_nil
    end
  end
end
