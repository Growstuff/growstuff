import React, {useState} from 'react';

// The member's API token, kept out of sight, with a button to copy it.
export default function ApiTokenCopy({token, copyLabel, copiedLabel}) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    try {
      await navigator.clipboard.writeText(token);
    } catch {
      return; // no clipboard here (an insecure page, say): nothing was copied, so don't say it was
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <span className="api-token-copy">
      <code aria-hidden="true">••••••••••••••••</code>
      <button type="button" className="btn btn-outline-dark btn-sm" onClick={copy}>
        <i className="far fa-copy" aria-hidden="true" /> {copied ? copiedLabel : copyLabel}
      </button>
      <span className="visually-hidden" role="status">{copied ? copiedLabel : ''}</span>
    </span>
  );
}
