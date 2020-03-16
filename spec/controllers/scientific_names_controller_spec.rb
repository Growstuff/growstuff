# frozen_string_literal: true

require 'rails_helper'

describe ScientificNamesController do
  login_member(:crop_wrangling_member)

  let!(:crop) { FactoryBot.create(:tomato) }

  def valid_attributes
    { name: 'Solanum lycopersicum', crop_id: crop.id }
  end

  describe "GET new" do
    it "assigns crop if specified" do
      get :new, params: { crop_id: crop.id }
      assigns(:crop).should be_an_instance_of Crop
    end
  end
end
