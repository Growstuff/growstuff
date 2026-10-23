import {render} from '@testing-library/react';
import {afterEach, describe, expect, it, vi} from 'vitest';

import useRecaptcha from './useRecaptcha';

let captcha;

function Probe({siteKey}) {
  captcha = useRecaptcha(siteKey);
  return <div ref={captcha.ref} />;
}

function stubGrecaptcha() {
  const grecaptcha = {render: vi.fn(() => 'widget-1'), getResponse: vi.fn(() => 'token'), reset: vi.fn(), ready: vi.fn((callback) => callback())};
  window.grecaptcha = grecaptcha;
  return grecaptcha;
}

describe('useRecaptcha', () => {
  afterEach(() => {
    delete window.grecaptcha;
    document.head.querySelectorAll('script').forEach((script) => script.remove());
  });

  describe('without a site key', () => {
    it('draws no widget', () => {
      const grecaptcha = stubGrecaptcha();
      render(<Probe siteKey={undefined} />);
      expect(grecaptcha.render).not.toHaveBeenCalled();
    });

    it('has no response to send', () => {
      render(<Probe siteKey={undefined} />);
      expect(captcha.response()).toBeUndefined();
    });

    it('does not load Google\'s script', () => {
      render(<Probe siteKey={undefined} />);
      expect(document.head.querySelector('script')).toBeNull();
    });
  });

  describe('with a site key', () => {
    it('draws the widget with the key', () => {
      const grecaptcha = stubGrecaptcha();
      render(<Probe siteKey="key" />);
      expect(grecaptcha.render).toHaveBeenCalledWith(expect.any(HTMLElement), {sitekey: 'key'});
    });

    it('gives the widget\'s response', () => {
      stubGrecaptcha();
      render(<Probe siteKey="key" />);
      expect(captcha.response()).toBe('token');
    });

    it('resets the widget', () => {
      const grecaptcha = stubGrecaptcha();
      render(<Probe siteKey="key" />);
      captcha.reset();
      expect(grecaptcha.reset).toHaveBeenCalledWith('widget-1');
    });

    it('loads Google\'s script when it is not there yet', () => {
      render(<Probe siteKey="key" />);
      expect(document.head.querySelector('script[src^="https://www.google.com/recaptcha/api.js"]')).not.toBeNull();
    });

    it('draws the widget once the script has loaded', () => {
      render(<Probe siteKey="key" />);
      const grecaptcha = stubGrecaptcha();
      document.head.querySelector('script').dispatchEvent(new Event('load'));
      expect(grecaptcha.render).toHaveBeenCalledTimes(1);
    });
  });
});
