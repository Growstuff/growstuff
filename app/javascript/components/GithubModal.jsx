import React from 'react';

import {csrfToken} from '../api';
import Modal from './Modal';

export default function GithubModal({urls, labels, onClose, requireTerms = false}) {
  return (
    <Modal title={labels.title} titleId="github-title" onClose={onClose} size={null}>
      <form method="post" action={urls.github}>
        <div className="modal-body fs-5">
          <input type="hidden" name="authenticity_token" value={csrfToken()} />
          <p>{labels.permission_note}</p>
          {requireTerms && <div className="form-check mt-3">
            <input id="github-tos" name="tos_agreement" type="checkbox" value="1" className="form-check-input" required />
            <label className="form-check-label" htmlFor="github-tos">
              {labels.agree_to_terms} <a href="/policy/tos" target="_blank" rel="noreferrer">{labels.terms_of_service}</a>
            </label>
          </div>}
        </div>
        <div className="modal-footer justify-content-between">
          <button type="button" className="btn btn-secondary" onClick={onClose}>{labels.cancel}</button>
          <button type="submit" className="btn btn-success">
            <i className="fab fa-github" aria-hidden="true" /> {labels.continue}
          </button>
        </div>
      </form>
    </Modal>
  );
}
