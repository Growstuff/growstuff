# frozen_string_literal: true

shared_examples "it is likeable" do
  let!(:likeable) { create(described_class.to_s.underscore.to_sym) }
  let!(:member1) { create(:member) }
  let!(:member2) { create(:member) }
  let!(:like1) { create(:like, member: member1, likeable: likeable) }
  let!(:like2) { create(:like, member: member2, likeable: likeable) }

  it "has many likes" do
    expect(likeable.likes.length).to eq 2
  end

  it 'has many members that likes it' do
    expect(likeable.members.length).to eq 2
  end

  it 'destroys the like when it is destroyed' do
    like_count = -1 * likeable.likes.count
    expect { likeable.destroy }.to change(Like, :count).by like_count
  end
end
