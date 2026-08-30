# frozen_string_literal: true

require 'rails_helper'

describe ScientificNamesController do
  login_member(:crop_wrangling_member)

  let!(:crop) { create(:tomato) }

  def valid_attributes
    { name: 'Solanum lycopersicum', crop_id: crop.id }
  end

  describe "GET new" do
    it "assigns crop if specified" do
      get :new, params: { crop_id: crop.id }
      expect(assigns(:crop)).to be_an_instance_of Crop
    end
  end
end
