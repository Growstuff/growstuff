# frozen_string_literal: true

require 'rails_helper'

describe "irregular crop inflections" do
  # We're just testing a couple of representative crops to
  # check that inflection works: you don't need to add
  # every crop here.
  it "crops which are mass nouns" do
    expect("kale".pluralize).to eq "kale"
    expect("broccoli".pluralize).to eq "broccoli"
    expect("square foot".pluralize).to eq "square feet"
    expect("squash".pluralize).to eq "squash"
    expect("bok choy".pluralize).to eq "bok choy"
    expect("achiote".pluralize).to eq "achiote"
    expect("alfalfa".pluralize).to eq "alfalfa"
    expect("allspice".pluralize).to eq "allspice"
    expect("spinach".pluralize).to eq "spinach"
    expect("garlic".pluralize).to eq "garlic"
    expect("licorice".pluralize).to eq "licorice"
    expect("lillipilli".pluralize).to eq "lillipillies"
    expect("barley".pluralize).to eq "barley"
    expect("Brassica oleracea Acephela group".pluralize).to eq "Brassica oleracea Acephela group"
    expect("common flax".pluralize).to eq "common flax"
    expect("cumin".pluralize).to eq "cumin"
    expect("Good King Henry".pluralize).to eq "Good King Henry"
    expect("oregano".pluralize).to eq "oregano"
    expect("star anise".pluralize).to eq "star anise"
  end

  it "crops which are particularly irregular" do
    expect("curry leaf".pluralize).to eq "curry leaves"
  end

  it "crops which require -es" do
    expect("mango".pluralize).to eq "mangoes"
    expect("potato".pluralize).to eq "potatoes"
  end

  it "crops where the first crop would normally be pluralized" do
    expect("Potato Onion".pluralize).to eq "Potato Onions"
    expect("pear tomato".pluralize).to eq "pear tomatoes"
    expect("chilli pepper".pluralize).to eq "chilli peppers"
  end

  it "crops where the proper name succeeds the crop that would normally be pluralized" do
    expect("potato Taranaki".pluralize).to eq "potato Taranaki"
    expect("potato Gladstone".pluralize).to eq "potato Gladstone"
    expect("potato matariki".pluralize).to eq "potato matariki"
    expect("spinach Santana".pluralize).to eq "spinach Santana"
  end

  it "crops of Māori origin" do
    expect("kūmara".pluralize).to eq "kūmara"
    expect("pūhā".pluralize).to eq "pūhā"
  end
end
