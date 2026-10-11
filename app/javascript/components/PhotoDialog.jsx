import React, {useEffect, useRef, useState} from 'react';

import AddPhotoModal from './AddPhotoModal';

// The add-photo dialog on a record page whose actions menu is still server
// rendered — a harvest, a seed, a garden. Nothing of its own is drawn: it
// listens for clicks on any [data-photo-dialog] link on the page (the "add
// photo" item in the kebab, the quiet "add" on the photos heading bar) and
// opens the same dialog the planting page opens.
//
// The link's own href is what the dialog works from — /photos/new?type=..&id=..
// — so it stays the fallback without JavaScript, and this island needs to know
// nothing about which record it is on beyond the name to show in the heading.
//
// Saving reloads, because the photos section is server rendered; the member
// stays on the record, which is the point.
export default function PhotoDialog({label, icon_url: iconUrl}) {
  // The href of the link the dialog was opened from, or null when closed.
  const [newUrl, setNewUrl] = useState(null);
  const open = useRef(null);
  open.current = setNewUrl;

  useEffect(() => {
    function onClick(event) {
      const trigger = event.target.closest('[data-photo-dialog]');
      if (!trigger) return;
      event.preventDefault();
      open.current(trigger.getAttribute('href'));
    }

    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);

  if (!newUrl) return null;

  return (
    <AddPhotoModal
      label={label}
      newUrl={newUrl}
      iconUrl={iconUrl}
      onClose={() => setNewUrl(null)}
      onAdded={() => {
        setNewUrl(null);
        // On the next tick: reloading from inside the dialog's own save tears
        // the page down mid-update and wedges the browser.
        setTimeout(() => window.location.reload(), 0);
      }}
    />
  );
}
