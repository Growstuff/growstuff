import React, {useState} from 'react';

import {csrfToken, postJson} from '../api';
import Modal from './Modal';

// The to-do row asking for an email, on the home page. The address is entered
// in a dialog over the page, and saying no thanks, or changing your mind about
// it, happen in place. Saving is an ordinary form post, because the list
// changes when it's saved (there is a link to confirm it).
//
// It renders the contents of the row: the server's own markup for the same row
// is inside the island's element, for anyone without JavaScript.
export default function EmailStep({number, declined: initiallyDeclined, urls, labels}) {
  const [declined, setDeclined] = useState(initiallyDeclined);
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function decline() {
    setBusy(true);
    setError('');
    try {
      const {ok} = await postJson(urls.decline, {});
      if (ok) {
        setDeclined(true);
        setOpen(false);
      } else {
        setError(labels.error);
      }
    } catch (failure) {
      setError(labels.error);
    }
    setBusy(false);
  }

  return (
    <>
      <span className={`home-step-number${declined ? ' skipped' : ''}`}>
        {declined ? <i className="fas fa-forward-step" role="img" aria-label={labels.skipped} title={labels.skipped} /> : number}
      </span>
      <div>
        <b>{labels.title}</b>
        <small className="home-section-note">
          {declined ? <>{labels.declined} <button type="button" className="btn btn-link p-0 align-baseline" onClick={() => setOpen(true)}>{labels.changed_mind}</button></> : labels.note}
        </small>
        {error && !open ? <small className="text-danger">{error}</small> : null}
      </div>
      {declined ? null : (
        <>
          <button type="button" className="btn btn-success" onClick={() => setOpen(true)}>{labels.add}</button>
          <button type="button" className="btn btn-outline-secondary" disabled={busy} onClick={decline}>{labels.decline}</button>
        </>
      )}
      {open ? (
        <Modal title={labels.title} titleId="email-step-title" onClose={() => setOpen(false)} size={null}>
          <form method="post" action={urls.update}>
            <div className="modal-body fs-5">
              <input type="hidden" name="_method" value="patch" />
              <input type="hidden" name="authenticity_token" value={csrfToken()} />
              <label className="form-label fw-semibold" htmlFor="email-step-email">{labels.title}</label>
              <input id="email-step-email" type="email" name="member[email]" className="form-control form-control-lg" placeholder="you@example.com" autoComplete="email" required />
              <div className="form-text">{labels.note}</div>
              {error ? <div className="text-danger mt-2">{error}</div> : null}
            </div>
            <div className="modal-footer d-block">
              <button type="submit" className="btn btn-success btn-lg w-100">{labels.save}</button>
              <p className="text-center fs-5 mb-0 mt-3">
                <button type="button" className="btn btn-link p-0" disabled={busy} onClick={decline}>{labels.decline}</button>
              </p>
            </div>
          </form>
        </Modal>
      ) : null}
    </>
  );
}
