require 'rails_helper'

describe ScientificNamesController do
  login_member(:crop_wrangling_member)

  let!(:crop) { FactoryBot.create(:tomato) }
  let!(:sci_name) { FactoryBot.create :scientific_name, name: 'aaa' }

  describe "GET new" do
    before { get :new, params: { crop_id: crop.id } }
    it { expect(assigns(:crop)).to eq crop }
    it { expect(assigns(:scientific_name)).to be_an_instance_of ScientificName }
  end

  describe 'GET index' do
    let!(:sci_name_last) { FactoryBot.create :scientific_name, name: 'zzz' }
    before { get :index }

    it "sorts by name" do
      expect(assigns(:scientific_names)).to eq [sci_name, sci_name_last]
    end
  end

  describe 'POST create' do
    subject { post :create, params: { scientific_name: { name: 'sciencey name', crop_id: crop.id } } }
    it { expect { subject }.to change { ScientificName.count }.by(1) }
    it { expect(subject.request.flash[:notice]).to_not be_nil }
  end

  describe 'DELETE destroy' do
    subject { delete :destroy, params: { id: sci_name.id } }
    it { expect { subject }.to change { ScientificName.count }.by(-1) }
    it { expect(subject.request.flash[:notice]).to_not be_nil }
  end
end
