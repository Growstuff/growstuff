require 'rails_helper'

describe 'home/_keep_in_touch.html.haml', :type => "view" do
  before :each do
    render
  end

  it 'has a heading' do
    assert_select 'h2', 'Keep in touch'
  end

  it 'links to twitter' do
    assert_select 'a', :href => 'http://twitter.com/growstufforg'
  end

  it 'links to facebook' do
    assert_select 'a', :href =>'https://www.facebook.com/Growstufforg'
  end  

  it 'links to the blog' do
    assert_select 'a', :href => 'http://blog.growstuff.org'
  end

  it 'links to the newsletter' do
    assert_select 'a', :href => 'http://blog.growstuff.org/newsletter'
  end

end
