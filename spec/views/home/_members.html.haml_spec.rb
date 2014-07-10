require 'spec_helper'

describe 'home/_members.html.haml', :type => "view" do
  before(:each) do
    @member = FactoryGirl.create(:london_member)
    @member.updated_at = 2.days.ago
    assign(:members, [@member])

    @planting = FactoryGirl.create(:planting, :owner => @member)
    render
  end

  it 'Has a heading' do
    rendered.should contain "Some of our members"
  end

  it 'Shows members' do
    rendered.should contain @member.login_name
    rendered.should contain @member.location
    rendered.should contain @planting.crop_name
  end

end
