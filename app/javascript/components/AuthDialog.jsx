import React, {useEffect, useRef, useState} from 'react';

import BlueskyModal from './BlueskyModal';
import {csrfToken} from '../api';
import MastodonModal from './MastodonModal';
import {closeOpenOffcanvases} from './Modal';
import SignInModal from './SignInModal';
import SignUpModal from './SignUpModal';

function authorizeGithub(url, termsAccepted = false) {
  const form = document.createElement('form');
  form.method = 'post';
  form.action = url;
  form.hidden = true;
  const fields = {authenticity_token: csrfToken()};
  if (termsAccepted === true) fields.tos_agreement = '1';
  Object.entries(fields).forEach(([name, value]) => {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    form.appendChild(input);
  });
  document.body.appendChild(form);
  form.submit();
  form.remove();
}

// The sign in, sign up and federated account dialogs for server-rendered links.
// Nothing of its own is drawn: it listens for clicks on any
// [data-auth-dialog="sign_in"], "sign_up", "bluesky" or "mastodon" link (the menu,
// the home page's buttons) and opens that dialog over the page. The layout
// mounts it once, for visitors who aren't signed in.
// GitHub links post directly to OAuth authorization instead of opening a dialog.
//
// The link's own href is the page for the same thing, so it stays the
// fallback without JavaScript.
export default function AuthDialog({urls, recaptcha_site_key: recaptchaSiteKey, site_name: siteName, github_labels: githubLabels}) {
  const [opened, setOpened] = useState(null);
  const open = useRef(null);
  open.current = setOpened;

  useEffect(() => {
    function onClick(event) {
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey) return;
      const trigger = event.target.closest('[data-auth-dialog]');
      if (!trigger) return;
      event.preventDefault();
      closeOpenOffcanvases(trigger);
      if (trigger.dataset.authDialog === 'github') {
        if (urls.github) authorizeGithub(urls.github);
        return;
      }
      open.current(trigger.dataset.authDialog);
    }

    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, [urls.github]);

  const onBluesky = urls.bluesky ? () => setOpened(opened === 'sign_up' ? 'bluesky_sign_up' : 'bluesky') : undefined;
  const onMastodon = urls.mastodon ? () => setOpened(opened === 'sign_up' ? 'mastodon_sign_up' : 'mastodon') : undefined;
  const onGithub = urls.github ? (termsAccepted) => authorizeGithub(urls.github, termsAccepted) : undefined;

  if (opened === 'sign_in') {
    return <SignInModal urls={urls} onClose={() => setOpened(null)} onSwitch={() => setOpened('sign_up')} onBluesky={onBluesky} onMastodon={onMastodon} onGithub={onGithub} githubLabel={githubLabels?.continue} />;
  }
  if (opened === 'sign_up') {
    return <SignUpModal urls={urls} recaptchaSiteKey={recaptchaSiteKey} siteName={siteName} onClose={() => setOpened(null)} onSwitch={() => setOpened('sign_in')} onBluesky={onBluesky} onMastodon={onMastodon} onGithub={onGithub} githubLabel={githubLabels?.continue} />;
  }
  if (opened === 'mastodon' || opened === 'mastodon_sign_up') {
    return <MastodonModal urls={urls} requireTerms={opened === 'mastodon_sign_up'} onClose={() => setOpened(null)} />;
  }
  if (opened === 'bluesky' || opened === 'bluesky_sign_up') {
    return <BlueskyModal urls={urls} requireTerms={opened === 'bluesky_sign_up'} onClose={() => setOpened(null)} />;
  }
  return null;
}
