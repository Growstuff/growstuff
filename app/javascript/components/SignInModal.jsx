import React, {useState} from 'react';

import {postJson} from '../api';
import {AuthFooter, CheckField, FormErrors, TextField} from './AuthFields';
import Modal from './Modal';

// Signing in, as a dialog over the page the link was on. It posts to Devise's
// own sessions#create as JSON, and on success reloads that page, now signed in
// (and showing Devise's "Signed in successfully"). A wrong login or password
// keeps the dialog open with the message.
export default function SignInModal({urls, onClose, onSwitch, onBluesky}) {
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
      setErrors([status === 401 && data && data.error ? data.error : 'Something went wrong signing in. Please try again.']);
    } catch (error) {
      setErrors(['Something went wrong signing in. Please try again.']);
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
            <CheckField id="sign-in-remember" label="Keep me signed in" checked={rememberMe} onChange={(event) => setRememberMe(event.target.checked)} />
            <a href={urls.forgot_password}>Forgot password?</a>
          </div>
        </div>
        <AuthFooter busy={saving} label="Sign in" busyLabel="Signing in…" prompt="New here?" switchLabel="Join free" switchHref={urls.sign_up_page} onSwitch={onSwitch} onBluesky={onBluesky} />
      </form>
    </Modal>
  );
}
