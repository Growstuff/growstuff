# frozen_string_literal: true

require 'rails_helper'

describe PagesController do
  {
    '/policy/tos'       => 'Growstuff Terms of Service',
    '/policy/privacy'   => 'Privacy Policy',
    '/policy/api'       => 'API and Data Use Policy',
    '/policy/community' => 'Growstuff Community Guidelines',
    '/support'          => 'Support - Frequently Asked Questions',
    '/about/contact'    => 'Contact'
  }.each do |path, heading|
    it "shows #{path}" do
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<h1")
      expect(response.body).to include(heading)
    end
  end
end
