# frozen_string_literal: true

class RobotsController < ApplicationController
  DEFAULT_FILENAME = 'config/robots.txt'

  def robots
    filename = "config/robots.#{subdomain}.txt" if subdomain && subdomain != 'www'
    file_to_render = File.exist?(filename.to_s) ? filename : DEFAULT_FILENAME
    render file: file_to_render, layout: false, content_type: 'text/plain'
  end

  private

  def subdomain
    request.subdomain.presence
  end
end
