require 'nominatim'

Nominatim.user_agent = Growstuff::Application.config.user_agent
Nominatim.user_agent_email = Growstuff::Application.config.user_agent_email
