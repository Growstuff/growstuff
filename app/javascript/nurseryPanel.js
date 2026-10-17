import {mountIslands, unmountIslands} from './islands';

// Shows the nursery as it is now, in place: fetches it from the server, swaps it
// for the one on the page and starts its React pieces. For when something was
// saved in a dialog over the page, so the page is never left. Falls back to
// reloading if that can't be done.
export async function refreshNursery() {
  const current = document.querySelector('.nursery-panel');
  if (!current) {
    window.location.reload();
    return;
  }
  try {
    const response = await fetch('/nursery/panel', {credentials: 'same-origin', headers: {Accept: 'text/html'}});
    if (!response.ok) throw new Error('could not load the nursery');
    const template = document.createElement('template');
    template.innerHTML = (await response.text()).trim();
    const fresh = template.content.firstElementChild;
    unmountIslands(current);
    current.replaceWith(fresh);
    mountIslands(fresh);
  } catch (error) {
    window.location.reload();
  }
}
