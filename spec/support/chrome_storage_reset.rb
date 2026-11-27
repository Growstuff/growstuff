# frozen_string_literal: true

# Capybara 3.40 clears Chrome storage with Storage.clearDataForOrigin('*'),
# which Chrome 158 rejects. Clear this page's local/session storage before
# navigating away, and use the browser-wide cookie command instead of '*'.
# Remove this workaround when Capybara's Chrome reset no longer uses '*'.
module ChromeStorageReset
  def reset!
    # ChromeDriver skips clear_storage when both storage options agree,
    # relying on the wildcard CDP command to clear local storage instead.
    clear_storage if @browser && uniform_storage_clear?
    super
  end

  private

  def execute_cdp(command, params = {})
    if command == 'Storage.clearDataForOrigin' && params[:origin] == '*'
      super('Network.clearBrowserCookies')
    else
      super
    end
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeStorageReset)
