import React, {useState} from 'react';

import {postJson} from '../api';
import {FormErrors, TextField} from './AuthFields';
import Modal from './Modal';

function failure(status, data) {
  if (status === 401 && data && data.error) return [data.error];
  return ['Something went wrong signing in. Please try again.'];
}

// Signing in, as a dialog over the page the link was on. It posts to Devise's
// own sessions#create as JSON, and on success reloads that page, now signed in
// (and showing Devise's "Signed in successfully"). A wrong login or password
// keeps the dialog open with the message.
export default function SignInModal({urls, onClose, onSwitch}) {
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(true);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  async function submit(event) {
    event.preventDefault();
    setSaving(true);
    setErrors([]);
    try {
      const {ok, status, data} = await postJson(urls.sign_in, {member: {login, password, remember_me: rememberMe ? '1' : '0'}});
      if (ok) {
        // On the next tick: reloading from inside the dialog's own save tears
        // the page down mid-update and wedges the browser.
        setTimeout(() => window.location.reload(), 0);
        return;
      }
      setErrors(failure(status, data));
    } catch (error) {
      setErrors(failure(0, null));
    }
    setSaving(false);
  }

  return (
    <Modal title="Sign in" titleId="sign-in-title" onClose={onClose} size={null}>
      <form onSubmit={submit} noValidate>
        <div className="modal-body fs-5">
          <FormErrors messages={errors} />
          <TextField id="sign-in-login" label="Login name or email" autoComplete="username" value={login} onChange={(event) => setLogin(event.target.value)} required />
          <TextField id="sign-in-password" label="Password" type="password" autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} required />
          <div className="d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div className="form-check">
              <input id="sign-in-remember" type="checkbox" className="form-check-input" checked={rememberMe} onChange={(event) => setRememberMe(event.target.checked)} />
              <label className="form-check-label" htmlFor="sign-in-remember">Keep me signed in</label>
            </div>
            <a href={urls.forgot_password}>Forgot password?</a>
          </div>
        </div>
        <div className="modal-footer d-block">
          <button type="submit" className="btn btn-success btn-lg w-100" disabled={saving} aria-busy={saving}>
            {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Signing in…</> : 'Sign in'}
          </button>
          <p className="text-center fs-5 mb-0 mt-3">
            New here? <a href={urls.sign_up_page} onClick={(event) => { event.preventDefault(); onSwitch(); }}>Join free</a>
          </p>
        </div>
      </form>
    </Modal>
  );
}
