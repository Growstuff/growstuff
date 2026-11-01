import React, {useEffect, useRef, useState} from 'react';

import BlueskyModal from './BlueskyModal';
import MastodonModal from './MastodonModal';
import SignInModal from './SignInModal';
import SignUpModal from './SignUpModal';

// The sign in, sign up and Bluesky dialogs for every server-rendered link to them.
// Nothing of its own is drawn: it listens for clicks on any
// [data-auth-dialog="sign_in"], "sign_up" or "bluesky" link (the menu,
// the home page's buttons) and opens that dialog over the page. The layout
// mounts it once, for visitors who aren't signed in.
//
// The link's own href is the page for the same thing, so it stays the
// fallback without JavaScript.
export default function AuthDialog({urls, recaptcha_site_key: recaptchaSiteKey, site_name: siteName}) {
  const [opened, setOpened] = useState(null); // 'sign_in', 'sign_up', 'bluesky' or null
  const open = useRef(null);
  open.current = setOpened;

  useEffect(() => {
    function onClick(event) {
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey) return;
      const trigger = event.target.closest('[data-auth-dialog]');
      if (!trigger) return;
      event.preventDefault();
      open.current(trigger.dataset.authDialog);
    }

    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);

  const onBluesky = urls.bluesky ? () => setOpened('bluesky') : undefined;
  const onMastodon = urls.mastodon ? () => setOpened('mastodon') : undefined;

  if (opened === 'sign_in') {
    return <SignInModal urls={urls} onClose={() => setOpened(null)} onSwitch={() => setOpened('sign_up')} onBluesky={onBluesky} onMastodon={onMastodon} />;
  }
  if (opened === 'sign_up') {
    return <SignUpModal urls={urls} recaptchaSiteKey={recaptchaSiteKey} siteName={siteName} onClose={() => setOpened(null)} onSwitch={() => setOpened('sign_in')} onBluesky={onBluesky} onMastodon={onMastodon} />;
  }
  if (opened === 'mastodon') {
    return <MastodonModal urls={urls} onClose={() => setOpened(null)} />;
  }
  if (opened === 'bluesky') {
    return <BlueskyModal urls={urls} onClose={() => setOpened(null)} />;
  }
  return null;
}
