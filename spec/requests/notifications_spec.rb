require 'spec_helper'

describe "Notifications" do
  describe "GET /notifications" do
    it "works! (now write some real specs)" do
      get notifications_path
      # can't see notifications because not logged in
      # therefore redirect to homepage
      response.status.should be(302)
    end
  end
end
