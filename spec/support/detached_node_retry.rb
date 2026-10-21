# frozen_string_literal: true

# When a page navigates while Capybara is querying it, Chrome can answer with
# "Node with given id does not belong to the document" rather than a stale
# element error. Capybara only retries the latter, so the spec fails on a page
# that was about to be fine. Retry this one as well.
module DetachedNodeRetry
  DETACHED = 'Node with given id does not belong to the document'

  protected

  def catch_error?(error, errors = nil)
    super || (error.is_a?(Selenium::WebDriver::Error::UnknownError) && error.message.include?(DETACHED))
  end
end

Capybara::Node::Base.prepend(DetachedNodeRetry)
