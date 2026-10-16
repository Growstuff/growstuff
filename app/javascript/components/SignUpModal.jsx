import React, {useState} from 'react';

import {postJson} from '../api';
import {AuthFooter, CheckField, FormErrors, TextField, fieldErrors} from './AuthFields';
import Modal from './Modal';
import useRecaptcha from './useRecaptcha';

const FIELDS = ['login_name', 'email', 'password', 'password_confirmation', 'tos_agreement'];
const FAILED = {byField: {}, other: ['Something went wrong joining. Please try again.']};

// Joining, as a dialog over the page the link was on. The same fields and
// checks as the sign up page: it posts to Devise's registrations#create as
// JSON, shows the server's errors against their fields, and on success goes to
// wherever the server would have sent the new member.
export default function SignUpModal({urls, recaptchaSiteKey, siteName, onClose, onSwitch}) {
  const [values, setValues] = useState({login_name: '', email: '', password: '', password_confirmation: '', tos_agreement: false, newsletter: true});
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState({byField: {}, other: []});
  const captcha = useRecaptcha(recaptchaSiteKey);

  const set = (name) => (event) => setValues({...values, [name]: event.target.type === 'checkbox' ? event.target.checked : event.target.value});

  async function submit(event) {
    event.preventDefault();
    setSaving(true);
    setErrors({byField: {}, other: []});
    try {
      const {ok, status, data} = await postJson(urls.sign_up, {member: values, 'g-recaptcha-response': captcha.response()});
      if (ok && data && data.location) {
        setTimeout(() => { window.location.href = data.location; }, 0);
        return;
      }
      setErrors(status === 422 ? fieldErrors(data, FIELDS) : FAILED);
    } catch (error) {
      setErrors(FAILED);
    }
    captcha.reset();
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
          <CheckField id="sign-up-tos" label={<>I agree to the <a href="/policy/tos" target="_blank" rel="noreferrer">Terms of Service</a></>} checked={values.tos_agreement} onChange={set('tos_agreement')} errors={on.tos_agreement} />
          <CheckField id="sign-up-newsletter" label={`Subscribe to the ${siteName} newsletter`} checked={values.newsletter} onChange={set('newsletter')} />
          {recaptchaSiteKey ? <div ref={captcha.ref} className="mt-3" /> : null}
          <p className="form-text mt-3 mb-0">If you have accessibility issues with the captcha, please contact us via the links in the footer and we will help.</p>
        </div>
        <AuthFooter busy={saving} label="Sign up" busyLabel="Joining…" prompt="Already a member?" switchLabel="Sign in" switchHref={urls.sign_in_page} onSwitch={onSwitch} />
      </form>
    </Modal>
  );
}
