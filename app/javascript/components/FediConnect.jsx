import React, {useState} from 'react';

import MastodonModal from './MastodonModal';

// The one button for adding a Mastodon, Pixelfed or other Fedi account from settings. It
// opens a dialog asking for the address of the server the account is on. `copy` is the
// dialog's wording and `url` is where the address is posted.
export default function FediConnect({url, buttonLabel, copy}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button type="button" className="btn btn-outline-dark" onClick={() => setOpen(true)}>
        <i className="fab fa-mastodon" aria-hidden="true" /> {buttonLabel}
      </button>
      {open && <MastodonModal urls={{mastodon: url}} copy={copy} onClose={() => setOpen(false)} />}
    </>
  );
}
