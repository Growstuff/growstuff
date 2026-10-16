import React, {useEffect, useRef, useState} from 'react';

import {postJson} from '../api';
import {FormErrors, TextField, fieldErrors} from './AuthFields';
import Modal from './Modal';

const FIELDS = ['login_name', 'email', 'password', 'password_confirmation', 'tos_agreement'];
const RECAPTCHA_SRC = 'https://www.google.com/recaptcha/api.js?render=explicit';

// Loads Google's script once, then calls back when `grecaptcha.render` is there.
function whenRecaptchaReady(callback) {
  if (window.grecaptcha && window.grecaptcha.render) {
    callback();
    return;
  }
  let script = document.querySelector(`script[src="${RECAPTCHA_SRC}"]`);
  if (!script) {
    script = document.createElement('script');
    script.src = RECAPTCHA_SRC;
    script.async = true;
    document.head.appendChild(script);
  }
  script.addEventListener('load', () => window.grecaptcha.ready(callback));
}

// Joining, as a dialog over the page the link was on. The same fields and
// checks as the sign up page: it posts to Devise's registrations#create as
// JSON, shows the server's errors against their fields, and on success goes to
// wherever the server would have sent the new member.
export default function SignUpModal({urls, recaptchaSiteKey, siteName, onClose, onSwitch}) {
  const [values, setValues] = useState({login_name: '', email: '', password: '', password_confirmation: '', tos_agreement: false, newsletter: true});
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState({byField: {}, other: []});
  const captcha = useRef(null);
  const captchaId = useRef(null);

  useEffect(() => {
    if (!recaptchaSiteKey || !captcha.current) return;
    whenRecaptchaReady(() => {
      if (captcha.current && captchaId.current === null) {
        captchaId.current = window.grecaptcha.render(captcha.current, {sitekey: recaptchaSiteKey});
      }
    });
  }, [recaptchaSiteKey]);

  const set = (name) => (event) => setValues({...values, [name]: event.target.type === 'checkbox' ? event.target.checked : event.target.value});

  async function submit(event) {
    event.preventDefault();
    setSaving(true);
    setErrors({byField: {}, other: []});
    const body = {member: values};
    if (captchaId.current !== null) body['g-recaptcha-response'] = window.grecaptcha.getResponse(captchaId.current);
    try {
      const {ok, status, data} = await postJson(urls.sign_up, body);
      if (ok && data && data.location) {
        setTimeout(() => { window.location.href = data.location; }, 0);
        return;
      }
      const shown = status === 422 ? fieldErrors(data, FIELDS) : {byField: {}, other: ['Something went wrong joining. Please try again.']};
      setErrors(shown);
    } catch (error) {
      setErrors({byField: {}, other: ['Something went wrong joining. Please try again.']});
    }
    if (captchaId.current !== null) window.grecaptcha.reset(captchaId.current);
    setSaving(false);
  }

  const on = errors.byField;
  return (
    <Modal title={`Join ${siteName}`} titleId="sign-up-title" onClose={onClose} size={null}>
      <form onSubmit={submit} noValidate>
        <div className="modal-body fs-5">
          <p>Sign up to track your vegetable garden and connect with other local growers.</p>
          <FormErrors messages={errors.other} />
          <TextField id="sign-up-login-name" label="Login name" hint="This is the name that will show on the website." autoComplete="username" value={values.login_name} onChange={set('login_name')} errors={on.login_name} required />
          <TextField id="sign-up-email" label="Email" type="email" hint="We'll use this address to contact you (we never spam!)" autoComplete="email" value={values.email} onChange={set('email')} errors={on.email} required />
          <TextField id="sign-up-password" label="Password" type="password" autoComplete="new-password" value={values.password} onChange={set('password')} errors={on.password} required />
          <TextField id="sign-up-password-confirmation" label="Password confirmation" type="password" autoComplete="new-password" value={values.password_confirmation} onChange={set('password_confirmation')} errors={on.password_confirmation} required />
          <div className="form-check mb-2">
            <input id="sign-up-tos" type="checkbox" className={`form-check-input${on.tos_agreement ? ' is-invalid' : ''}`} checked={values.tos_agreement} onChange={set('tos_agreement')} aria-describedby={on.tos_agreement ? 'sign-up-tos-errors' : undefined} />
            <label className="form-check-label" htmlFor="sign-up-tos">I agree to the <a href="/policy/tos" target="_blank" rel="noreferrer">Terms of Service</a></label>
            {on.tos_agreement ? <div className="invalid-feedback d-block" id="sign-up-tos-errors">{on.tos_agreement.join(', ')}</div> : null}
          </div>
          <div className="form-check mb-3">
            <input id="sign-up-newsletter" type="checkbox" className="form-check-input" checked={values.newsletter} onChange={set('newsletter')} />
            <label className="form-check-label" htmlFor="sign-up-newsletter">Subscribe to the {siteName} newsletter</label>
          </div>
          {recaptchaSiteKey ? <div ref={captcha} /> : null}
          <p className="form-text mb-0">If you have accessibility issues with the captcha, please contact us via the links in the footer and we will help.</p>
        </div>
        <div className="modal-footer d-block">
          <button type="submit" className="btn btn-success btn-lg w-100" disabled={saving} aria-busy={saving}>
            {saving ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> Joining…</> : 'Sign up'}
          </button>
          <p className="text-center fs-5 mb-0 mt-3">
            Already a member? <a href={urls.sign_in_page} onClick={(event) => { event.preventDefault(); onSwitch(); }}>Sign in</a>
          </p>
        </div>
      </form>
    </Modal>
  );
}
