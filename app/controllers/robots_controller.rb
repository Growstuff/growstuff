class RobotsController < ApplicationController
  def robots
    subdomain = request.subdomain

    filename = if subdomain.present? && subdomain != 'www'
      "robots.#{ subdomain }.txt"
    else
      "robots.txt"
    end

    robots_text = File.read(Rails.root.join('config', filename))

    respond_to do |format|
      format.text { render text: robots_text, layout: false }
    end
  end
end
