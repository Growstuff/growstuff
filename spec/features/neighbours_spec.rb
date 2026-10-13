# frozen_string_literal: true

require 'rails_helper'

describe 'My friends and neighbours' do
  let(:member) { create_located_member('Wellington, NZ', -41.29, 174.78) }

  before do
    Rails.cache.clear
    login_as member
  end

  it 'is not for visitors' do
    logout
    visit neighbours_path
    expect(page).to have_current_path(new_member_session_path)
  end

  it 'shows what the people they follow and the ones nearby have been doing' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    create(:planting, owner: friend, garden: friend.gardens.first, planted_at: Time.zone.today)
    neighbour = create_located_member('Miramar, Wellington', -41.3, 174.8, login_name: 'nextdoor')
    create(:harvest, owner: neighbour, harvested_at: Time.zone.today)

    visit neighbours_path
    expect(page).to have_css('h2', text: 'Latest from your friends and neighbours')
    expect(page).to have_css('article', text: /friendly.*following.*Planted/m)
    expect(page).to have_css('article', text: /nextdoor.*near you.*Harvested/m)
  end

  it 'stops suggesting someone who is dismissed' do
    crop = create(:crop)
    create(:planting, owner: member, garden: member.gardens.first, crop:)
    other = create(:member, login_name: 'sameplants')
    create(:planting, owner: other, garden: other.gardens.first, crop:)

    visit neighbours_path
    expect(page).to have_css('h2', text: 'Who to follow')
    click_button 'Stop suggesting sameplants'
    expect(page).to have_no_css('h2', text: 'Who to follow')
  end

  it 'follows someone who is suggested' do
    crop = create(:crop)
    create(:planting, owner: member, garden: member.gardens.first, crop:)
    other = create(:member, login_name: 'sameplants')
    create(:planting, owner: other, garden: other.gardens.first, crop:)

    visit neighbours_path
    click_button 'Follow'
    page.document.synchronize { raise Capybara::ExpectationNotMet, 'not followed yet' unless member.followed.reload.include?(other) }
  end

  it 'says so when they have not said where they live' do
    member.update!(location: '', latitude: nil, longitude: nil)
    visit neighbours_path
    expect(page).to have_link('Add where you live')
  end
end
