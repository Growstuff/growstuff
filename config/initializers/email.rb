module Growstuff
  class Application < Rails::Application
    config.x.email = {
      from: ENV.fetch('GROWSTUFF_EMAIL', 'info@growstuff.org'),
      admin: ENV.fetch('GROWSTUFF_ADMIN_EMAIL', 'sysadmin@growstuff.org'),
      support: ENV.fetch('GROWSTUFF_SUPPORT_EMAIL', 'info@growstuff.org')
    }
  end
end
