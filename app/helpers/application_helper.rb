module ApplicationHelper

  def random_crop
    Crop.random
  end

  def support_address
		Growstuff::Application.config.support_address
	end

	def media_address
		Growstuff::Application.config.media_address
  end

  def info_address
    Growstuff::Application.config.info_address
  end

  def site_name
    Growstuff::Application.config.site_name
  end

  def email_from_address
    Growstuff::Application.config.email_from_address
  end

end
