import React, {useEffect, useState} from 'react';

import {csrfToken} from '../api';
import Modal from './Modal';

export default function MastodonModal({urls, onClose}) {
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const reset = () => setBusy(false);
    window.addEventListener('pageshow', reset);
    return () => window.removeEventListener('pageshow', reset);
  }, []);

  return (
    <Modal title="Sign in with Mastodon" titleId="mastodon-title" onClose={onClose} size={null}>
      <form method="post" action={urls.mastodon} onSubmit={() => setBusy(true)}>
        <div className="modal-body fs-5">
          <input type="hidden" name="authenticity_token" value={csrfToken()} />
          <label className="form-label fw-semibold" htmlFor="mastodon-address">Mastodon address</label>
          <input id="mastodon-address" name="identifier" className="form-control form-control-lg" placeholder="alice@mastodon.social" autoComplete="username" autoCapitalize="none" spellCheck={false} required />
          <div className="form-text">We only ask who you are. We can't post for you.</div>
          <div className="form-check mt-3">
            <input id="mastodon-tos" name="tos_agreement" type="checkbox" value="1" className="form-check-input" required />
            <label className="form-check-label" htmlFor="mastodon-tos">
              I agree to the <a href="/policy/tos" target="_blank" rel="noreferrer">Terms of Service</a>
            </label>
          </div>
        </div>
        <div className="modal-footer d-block">
          <button type="submit" className="btn btn-success btn-lg w-100" disabled={busy} aria-busy={busy}>
            {busy ? 'Contacting Mastodon, one moment…' : 'Continue with Mastodon'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
