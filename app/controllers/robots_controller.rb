class RobotsController < ApplicationController
  def robots
    subdomain = request.subdomain

    filename = if subdomain.present? && subdomain != 'www'
      "robots.#{ subdomain }.txt"
    else
      "robots.txt"
    end

    render file: "config/#{ filename }", layout: false, content_type: 'text/plain'
  end
end
