# frozen_string_literal: true

require 'rails_helper'

describe Authentication do
  subject(:authentication) { create(:authentication) }

  it { is_expected.to be_an_instance_of described_class }
  it { expect(authentication.member).to be_an_instance_of Member }
end
