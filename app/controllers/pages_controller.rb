# frozen_string_literal: true

class PagesController < ApplicationController
  skip_authorize_resource
  respond_to :html

  def tos; end

  def privacy; end

  def data_use; end

  def community_guidelines; end

  def support; end

  def contact; end

  def letsencrypt
    # use your code here, not mine
    render text: "y9KNck8wqkoQLnlr2RgA2TVwWtyYb4PeY_hzGNx0Tfs.dlIPqFhMDCLyQEccczY3roHZ1UWu6UqVeyb9mkRxheU"
  end
end
