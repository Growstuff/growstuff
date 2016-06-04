require 'spec_helper'

feature "irregular crop inflections" do
  # We're just testing a couple of representative crops to
  # check that inflection works: you don't need to add
  # every crop here.
  scenario "crops which are mass nouns" do
    expect("kale".pluralize).to eq "kale"
    expect("broccoli".pluralize).to eq "broccoli"
  end
end
