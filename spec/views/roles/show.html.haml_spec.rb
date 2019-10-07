require 'rails_helper'

describe 'roles/show' do
  before { @role = assign(:role, stub_model(Role, name: 'Name', description: 'MyText')) }

  it 'renders attributes in <p>' do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/MyText/)
  end
end
