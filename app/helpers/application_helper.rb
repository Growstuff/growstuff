module ApplicationHelper

  def random_crop
    Crop.random
  end

  def site_name
    Growstuff::Application.config.site_name
  end

  def company_name
    Growstuff::Application.config.company_name
  end

  def host_name
    Growstuff::Application.config.action_mailer.default_url_options[:host]
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

  def email_from_address
    Growstuff::Application.config.email_from_address
  end

end
