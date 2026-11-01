import React from 'react';

const humanize = (key) => key.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase());

// Devise's `errors` ({field: [messages]}) split into the messages for the
// fields named, to show against their inputs, and the rest (the captcha, say),
// to show above the form.
export function fieldErrors(data, fields) {
  const byField = {};
  const other = [];
  Object.entries((data && data.errors) || {}).forEach(([key, messages]) => {
    messages.forEach((message) => {
      if (fields.includes(key)) {
        byField[key] = [...(byField[key] || []), message];
      } else {
        other.push(key === 'base' ? message : `${humanize(key)} ${message}`);
      }
    });
  });
  return {byField, other};
}

function Errors({id, messages}) {
  if (messages.length === 0) return null;
  return <div className="invalid-feedback d-block" id={id}>{messages.join(', ')}</div>;
}

// A labelled input with its errors under it, wired up for assistive technology.
export function TextField({id, label, hint, errors = [], ...inputProps}) {
  const describedBy = [hint ? `${id}-hint` : null, errors.length > 0 ? `${id}-errors` : null].filter(Boolean).join(' ') || undefined;
  return (
    <div className="mb-3">
      <label className="form-label fw-semibold" htmlFor={id}>{label}</label>
      <input
        id={id}
        className={`form-control form-control-lg${errors.length > 0 ? ' is-invalid' : ''}`}
        aria-describedby={describedBy}
        aria-invalid={errors.length > 0 || undefined}
        {...inputProps}
      />
      {hint ? <div className="form-text" id={`${id}-hint`}>{hint}</div> : null}
      <Errors id={`${id}-errors`} messages={errors} />
    </div>
  );
}

// A checkbox; `label` may contain a link.
export function CheckField({id, label, errors = [], ...inputProps}) {
  return (
    <div className="form-check mb-2">
      <input
        id={id}
        type="checkbox"
        className={`form-check-input${errors.length > 0 ? ' is-invalid' : ''}`}
        aria-describedby={errors.length > 0 ? `${id}-errors` : undefined}
        {...inputProps}
      />
      <label className="form-check-label" htmlFor={id}>{label}</label>
      <Errors id={`${id}-errors`} messages={errors} />
    </div>
  );
}

export function FormErrors({messages}) {
  if (messages.length === 0) return null;
  return (
    <div className="alert alert-danger" role="alert">
      {messages.map((message) => <div key={message}>{message}</div>)}
    </div>
  );
}

// The foot of both dialogs: the submit button, the way in with Bluesky when
// it is switched on (`onBluesky` given), and the link across to the other dialog.
export function AuthFooter({busy, label, busyLabel, prompt, switchLabel, switchHref, onSwitch, onBluesky}) {
  return (
    <div className="modal-footer d-block">
      <button type="submit" className="btn btn-success btn-lg w-100" disabled={busy} aria-busy={busy}>
        {busy ? <><i className="fas fa-spinner fa-spin" aria-hidden="true" /> {busyLabel}</> : label}
      </button>
      {onBluesky ? (
        <button type="button" className="btn btn-outline-dark btn-lg w-100 mt-3" onClick={onBluesky}>
          <i className="fab fa-bluesky bluesky-icon" aria-hidden="true" /> Continue with Bluesky
        </button>
      ) : null}
      <p className="text-center fs-5 mb-0 mt-3">
        {prompt} <a href={switchHref} onClick={(event) => { event.preventDefault(); onSwitch(); }}>{switchLabel}</a>
      </p>
    </div>
  );
}
