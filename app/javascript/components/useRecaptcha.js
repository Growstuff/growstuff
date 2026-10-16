import {useEffect, useRef} from 'react';

const SRC = 'https://www.google.com/recaptcha/api.js?render=explicit';

// Loads Google's script once, then calls back when `grecaptcha.render` is there.
function whenReady(callback) {
  if (window.grecaptcha && window.grecaptcha.render) {
    callback();
    return;
  }
  let script = document.querySelector(`script[src="${SRC}"]`);
  if (!script) {
    script = document.createElement('script');
    script.src = SRC;
    script.async = true;
    document.head.appendChild(script);
  }
  script.addEventListener('load', () => window.grecaptcha.ready(callback));
}

// A reCAPTCHA checkbox drawn into the element `ref` is put on, when there is a
// site key. `response()` is what to send with the form (nothing without a key),
// and `reset()` clears it after a failed attempt.
export default function useRecaptcha(siteKey) {
  const ref = useRef(null);
  const widgetId = useRef(null);

  useEffect(() => {
    if (!siteKey || !ref.current) return;
    whenReady(() => {
      if (ref.current && widgetId.current === null) {
        widgetId.current = window.grecaptcha.render(ref.current, {sitekey: siteKey});
      }
    });
  }, [siteKey]);

  return {
    ref,
    response: () => (widgetId.current === null ? undefined : window.grecaptcha.getResponse(widgetId.current)),
    reset: () => { if (widgetId.current !== null) window.grecaptcha.reset(widgetId.current); },
  };
}
