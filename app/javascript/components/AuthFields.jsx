import React from 'react';

// Devise's error keys, as the field they belong to, for showing each message
// against its input. Anything else (the captcha, say) is shown above the form.
export function fieldErrors(data, fields) {
  const errors = data && data.errors ? data.errors : {};
  const byField = {};
  const other = [];
  Object.entries(errors).forEach(([key, messages]) => {
    messages.forEach((message) => {
      if (fields.includes(key)) {
        byField[key] = [...(byField[key] || []), message];
      } else {
        other.push(key === 'base' ? message : `${key.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase())} ${message}`);
      }
    });
  });
  return {byField, other};
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
      {errors.length > 0 ? <div className="invalid-feedback d-block" id={`${id}-errors`}>{errors.join(', ')}</div> : null}
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
