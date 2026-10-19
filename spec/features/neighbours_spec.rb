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

  it 'shows a friend transplanting a tomato into the big garden' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    tomato = create(:crop, name: 'tomato')
    planting = create(:planting, owner: friend, garden: friend.gardens.first, crop: tomato, planted_at: 1.week.ago)
    planting.transplant_to(create(:garden, owner: friend, name: 'Big garden'), on: Time.zone.today)

    visit neighbours_path
    expect(page).to have_css('article', text: /friendly.*Transplanted tomato into Big garden/m)
  end

  it 'says planted out when the planting came from the nursery' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    nursery = friend.gardens.first
    nursery.update!(nursery: true)
    planting = create(:planting, owner: friend, garden: nursery, crop: create(:crop, name: 'tomato'), planted_at: 1.week.ago)
    planting.transplant_to(create(:garden, owner: friend, name: 'The Deck'), on: Time.zone.today)

    visit neighbours_path
    expect(page).to have_css('article', text: /friendly.*Planted out tomato into The Deck/m)
  end

  it 'lists what a friend harvested in one sentence' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    %w(tomato basil).each do |name|
      create(:harvest, owner: friend, crop: create(:crop, name:), harvested_at: Time.zone.today, quantity: nil, weight_quantity: nil)
    end

    visit neighbours_path
    expect(page).to have_css('article p', text: /Harvested (tomato and basil|basil and tomato)/)
  end

  it 'says how much a friend harvested when they said' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    create(:harvest, owner: friend, crop: create(:crop, name: 'tomato'), harvested_at: Time.zone.today,
                     quantity: 3, unit: 'bunch', weight_quantity: 2, weight_unit: 'kg')

    visit neighbours_path
    expect(page).to have_css('article p', text: /Harvested tomato \(3 bunches, weighing 2 kg\)/)
  end

  it 'shows a friend finishing a planting' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    planting = create(:planting, owner: friend, garden: friend.gardens.first, crop: create(:crop, name: 'tomato'), planted_at: 1.month.ago)
    planting.update!(finished: true, finished_at: Time.zone.today)

    visit neighbours_path
    expect(page).to have_css('article', text: /friendly.*Finished growing tomato/m)
  end

  it 'shows a friend finishing with a packet of seeds' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    create(:seed, owner: friend, crop: create(:crop, name: 'tomato'), finished: true, finished_at: Time.zone.today)

    visit neighbours_path
    expect(page).to have_css('article', text: /friendly.*Finished with tomato seeds/m)
  end

  it 'shows a friend planning an activity' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    create(:activity, owner: friend, name: 'Weed the beans', due_date: Time.zone.today + 1.month)

    due = (Time.zone.today + 1.month).strftime('%-d %b')
    visit neighbours_path
    expect(page).to have_css('article', text: /friendly.*Planned an activity, Weed the beans \(for #{due}\)/m)
  end

  it 'shows only their own activity under Me' do
    friend = create(:member, login_name: 'friendly')
    member.follows.create!(followed: friend)
    create(:planting, owner: friend, garden: friend.gardens.first, planted_at: Time.zone.today)
    create(:harvest, owner: member, harvested_at: Time.zone.today)

    visit neighbours_path(scope: 'me')
    expect(page).to have_css('article', text: /Harvested/).and have_no_css('article', text: /friendly/)
  end

  it 'marks where the season changes' do
    create(:harvest, owner: member, harvested_at: Date.new(2026, 10, 20))
    create(:harvest, owner: member, harvested_at: Date.new(2026, 8, 20))

    visit neighbours_path(scope: 'me')
    expect(page).to have_css('h2.neighbours-season', text: 'Spring 2026').and have_css('h2.neighbours-season', text: 'Winter 2026')
  end

  it 'names the season in the other hemisphere too' do
    friend = create_located_member('Oslo', 59.9, 10.7, login_name: 'norwegian')
    member.follows.create!(followed: friend)
    create(:harvest, owner: friend, harvested_at: Date.new(2026, 10, 20))

    visit neighbours_path
    expect(page).to have_css('h2.neighbours-season', text: 'Spring 2026 · Autumn in the northern hemisphere')
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
