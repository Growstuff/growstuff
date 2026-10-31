import React, {useEffect, useState} from 'react';

import {csrfToken} from '../api';
import Modal from './Modal';

// Signing in with Bluesky, as a dialog over the page the link was on. The
// handle decides where the member is sent to approve us, so this is a plain
// form posting straight to the server, which answers with a redirect to their
// Bluesky server.
export default function BlueskyModal({urls, onClose}) {
  const [busy, setBusy] = useState(false);

  // Coming back with the browser's back button can restore this page as it was
  // left, mid-submit.
  useEffect(() => {
    const reset = () => setBusy(false);
    window.addEventListener('pageshow', reset);
    return () => window.removeEventListener('pageshow', reset);
  }, []);

  return (
    <Modal title="Sign in with Bluesky" titleId="bluesky-title" onClose={onClose} size={null}>
      <form method="post" action={urls.bluesky} onSubmit={() => setBusy(true)}>
        <div className="modal-body fs-5">
          <input type="hidden" name="authenticity_token" value={csrfToken()} />
          <label className="form-label fw-semibold" htmlFor="bluesky-handle">Bluesky handle</label>
          <input id="bluesky-handle" name="handle" className="form-control form-control-lg" placeholder="alice.bsky.social" autoComplete="username" autoCapitalize="none" spellCheck={false} required />
          <div className="form-text">We only ask who you are. We can't post for you.</div>
          <div className="form-check mt-3">
            <input id="bluesky-tos" name="tos_agreement" type="checkbox" value="1" className="form-check-input" required />
            <label className="form-check-label" htmlFor="bluesky-tos">
              I agree to the <a href="/policy/tos" target="_blank" rel="noreferrer">Terms of Service</a>
            </label>
          </div>
        </div>
        <div className="modal-footer d-block">
          <button type="submit" className="btn btn-success btn-lg w-100" disabled={busy} aria-busy={busy}>
            {busy ?
              <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Contacting Bluesky, one moment…</> :
              <><i className="fab fa-bluesky bluesky-icon" aria-hidden="true" /> Continue with Bluesky</>}
          </button>
        </div>
      </form>
    </Modal>
  );
}
