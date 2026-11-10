# frozen_string_literal: true

require 'rails_helper'

describe PagesController do
  {
    '/policy/tos'       => 'Growstuff Terms of Service',
    '/policy/privacy'   => 'Privacy Policy',
    '/policy/api'       => 'API and Data Use Policy',
    '/policy/community' => 'Growstuff Community Guidelines',
    '/support'          => 'Support - Frequently Asked Questions',
    '/about/contact'    => 'Contact',
    '/about'            => 'About',
    '/policy'           => 'Policy',
    '/policy/copyright' => 'Copyright Infringement Policy'
  }.each do |path, heading|
    describe "shows #{path}" do
      before { get path }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response.body).to include("<h1") }
      it { expect(response.body).to include(heading) }
    end
  end
end
