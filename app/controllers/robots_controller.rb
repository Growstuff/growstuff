class RobotsController < ApplicationController

  DEFAULT_FILENAME = 'config/robots.txt'.freeze

  def robots
    filename = if subdomain && subdomain != 'www'
      "config/robots.#{ subdomain }.txt"
    end

    file_to_render = File.exists?(filename.to_s) ? filename : DEFAULT_FILENAME

    render file: file_to_render, layout: false, content_type: 'text/plain'
  end

  private

  def subdomain
    request.subdomain.present? ? request.subdomain : nil
  end
end
