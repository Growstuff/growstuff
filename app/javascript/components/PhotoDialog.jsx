import React, {useEffect, useRef, useState} from 'react';

import AddPhotoModal from './AddPhotoModal';

// The add-photo dialog for every server-rendered "add photo" link. Nothing of
// its own is drawn: it listens for clicks on any [data-photo-dialog] link on
// the page (the "add photo" item in a menu, the quiet "add" on the photos
// heading bar) and opens the same dialog the planting page opens. The layout
// mounts it once.
//
// The link's own href is what the dialog works from — /photos/new?type=..&id=..
// — so it stays the fallback without JavaScript, and its data-photo-label names
// the record in the heading.
//
// Saving reloads, because the photos section is server rendered; the member
// stays on the record, which is the point.
export default function PhotoDialog({label, icon_url: iconUrl}) {
  // The link the dialog was opened from ({href, label}), or null when closed.
  const [opened, setOpened] = useState(null);
  const open = useRef(null);
  open.current = setOpened;

  useEffect(() => {
    function onClick(event) {
      const trigger = event.target.closest('[data-photo-dialog]');
      if (!trigger) return;
      event.preventDefault();
      open.current({href: trigger.getAttribute('href'), label: trigger.dataset.photoLabel});
    }

    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);

  if (!opened) return null;

  return (
    <AddPhotoModal
      label={opened.label || label}
      newUrl={opened.href}
      iconUrl={iconUrl}
      onClose={() => setOpened(null)}
      onAdded={() => {
        setOpened(null);
        // On the next tick: reloading from inside the dialog's own save tears
        // the page down mid-update and wedges the browser.
        setTimeout(() => window.location.reload(), 0);
      }}
    />
  );
}
