// A seed's packet sheet edits in place: "Edit all", and the Edit item in the page's
// menu, swap the list of facts for a form in the same spot, with the packet still
// beside it. Without JavaScript the menu's Edit goes to the form's own page.

export function setEditing(sheet, editing) {
  sheet.classList.toggle('is-editing', editing);
  if (!editing) return;
  // Editing is when the text is wanted beside the fields, so it opens by itself.
  sheet.querySelector('.seed-packet-text-toggle[aria-expanded="false"]')?.click();
  sheet.querySelector('.packet-sheet-form [name^="seed["]')?.focus({ preventScroll: true });
}

// A packet photo fits the panel; a click shows it full size inside the panel, which
// scrolls, to read the small print. The bigger copy is fetched when first asked for.
export function toggleZoom(link) {
  const photos = link.closest('.seed-packet-photos');
  const image = link.querySelector('img');
  const zoomed = photos.classList.toggle('is-zoomed');
  image.dataset.fit ||= image.getAttribute('src');
  if (zoomed && image.dataset.large) {
    image.onerror = () => { image.src = image.dataset.fit; };
    image.src = image.dataset.large;
  } else {
    image.src = image.dataset.fit;
  }
}

export function initPacketSheet(root = document) {
  root.addEventListener('click', (event) => {
    const photo = event.target.closest('.seed-packet-photos a');
    if (photo && !(event.ctrlKey || event.metaKey || event.shiftKey)) {
      event.preventDefault();
      toggleZoom(photo);
      return;
    }

    const sheet = root.querySelector('[data-packet-sheet]');
    if (!sheet) return;

    if (event.target.closest('[data-packet-sheet-edit]')) {
      event.preventDefault();
      setEditing(sheet, true);
      sheet.scrollIntoView({ block: 'start', behavior: 'smooth' });
    } else if (event.target.closest('[data-packet-sheet-cancel]')) {
      event.preventDefault();
      setEditing(sheet, false);
    }
  });
}

initPacketSheet();
