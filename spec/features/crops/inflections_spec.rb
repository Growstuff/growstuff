require 'rails_helper'

feature "irregular crop inflections" do
  # We're just testing a couple of representative crops to
  # check that inflection works: you don't need to add
  # every crop here.
  scenario "crops which are mass nouns" do
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
  end
end
