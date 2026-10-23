# frozen_string_literal: true

# Catches pages that are wider than a phone screen. A page overruns when
# something sticks out past the viewport's right edge, which makes the whole
# page scroll sideways. The matcher names the elements responsible, so a
# failure points at the markup to fix.
#
#   resize_to_phone
#   visit root_path
#   expect(page).to have_no_horizontal_overflow
module OverflowHelpers
  # Pixel 7, the phone the overrun in #4924 was reported on.
  PHONE = { width: 412, height: 915 }.freeze

  # Elements whose right edge is past the viewport, unless they are hidden
  # (such as the closed menu drawer) or an ancestor clips or scrolls them
  # (overflow other than visible), as that overflow is contained. Reports the
  # outermost offenders only.
  FIND_OVERFLOWING = <<~JS
    const limit = document.documentElement.clientWidth;
    const clipped = (el) => {
      for (let p = el.parentElement; p; p = p.parentElement) {
        if (getComputedStyle(p).overflowX !== 'visible') return true;
      }
      return false;
    };
    const offenders = [...document.body.querySelectorAll('*')].filter((el) => {
      const box = el.getBoundingClientRect();
      return box.width > 0 && box.right > limit + 1 && getComputedStyle(el).visibility !== 'hidden' && !clipped(el);
    });
    return offenders
      .filter((el) => !offenders.includes(el.parentElement))
      .map((el) => {
        const id = el.id ? `#${el.id}` : '';
        const classes = [...el.classList].map((name) => `.${name}`).join('');
        return `${el.tagName.toLowerCase()}${id}${classes} (right edge ${Math.round(el.getBoundingClientRect().right)}px of ${limit}px)`;
      });
  JS

  def resize_to_phone
    page.driver.browser.manage.window.resize_to(PHONE[:width], PHONE[:height])
  end
end

RSpec::Matchers.define :have_no_horizontal_overflow do
  match do |page|
    @offenders = page.evaluate_script("(() => { #{OverflowHelpers::FIND_OVERFLOWING} })()")
    @offenders.empty?
  end

  failure_message do
    "expected page to fit the viewport width, but these overrun it:\n  #{@offenders.join("\n  ")}"
  end
end

RSpec.configure do |config|
  config.include OverflowHelpers, type: :feature
  config.after(:each, :phone) do
    # Back to the desktop size the :js hook sets, as browser sessions are reused.
    page.driver.browser.manage.window.resize_to(1920, 1080)
  end
end
