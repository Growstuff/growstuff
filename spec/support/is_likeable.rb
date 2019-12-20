# frozen_string_literal: true

shared_examples "it is likeable" do
  before do
    # Possibly a horrible hack.
    # Will fail if factory name does not match the model name..
    @likeable = FactoryBot.create(described_class.to_s.underscore.to_sym)
    @member1 = FactoryBot.create(:member)
    @member2 = FactoryBot.create(:member)
    @like1 = FactoryBot.create(:like, member: @member1, likeable: @likeable)
    @like2 = FactoryBot.create(:like, member: @member2, likeable: @likeable)
  end

  it "has many likes" do
    expect(@likeable.likes.length).to eq 2
  end

  it 'has many members that likes it' do
    expect(@likeable.members.length).to eq 2
  end

  it 'destroys the like when it is destroyed' do
    like_count = -1 * @likeable.likes.count
    expect { @likeable.destroy }.to change(Like, :count).by like_count
  end
end
