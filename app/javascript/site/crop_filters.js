// The filters on the crop list apply as soon as one changes: the form is fetched afresh with what is chosen, and the
// list, the status under the filters and the address of the page are swapped for what comes back, without reloading.
// The Filter button stays for when this script isn't running, and is hidden when it is.
const RESULTS = '#crop-results';
const STATUS = '.crop-filter-status';

// The address of the page for what the form has chosen, leaving out the fields with nothing in them.
export function filterUrl(form) {
  const params = new URLSearchParams();
  new FormData(form).forEach((value, key) => {
    if (value !== '') params.append(key, value);
  });
  const query = params.toString();
  return query ? `${form.getAttribute('action')}?${query}` : form.getAttribute('action');
}

// Takes the list and the status from the page that came back, and puts them in this one.
export function swapIn(html, doc = document) {
  const fresh = new DOMParser().parseFromString(html, 'text/html');
  [RESULTS, STATUS].forEach((selector) => {
    const current = doc.querySelector(selector);
    const replacement = fresh.querySelector(selector);
    if (current && replacement) current.replaceWith(replacement);
  });
}

export function setUp(form, fetcher = fetch) {
  let pending = null;
  const apply = form.querySelector('.crop-filters-apply');
  if (apply) apply.hidden = true;

  form.addEventListener('change', async () => {
    const url = filterUrl(form);
    if (pending) pending.abort();
    pending = new AbortController();
    form.setAttribute('aria-busy', 'true');
    try {
      const response = await fetcher(url, { headers: { Accept: 'text/html' }, credentials: 'same-origin', signal: pending.signal });
      if (!response.ok) throw new Error('could not load the crops');
      swapIn(await response.text());
      window.history.replaceState(null, '', url);
    } catch (error) {
      if (error.name !== 'AbortError') window.location.assign(url);
    } finally {
      form.removeAttribute('aria-busy');
    }
  });
}

document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('form.crop-filters');
  if (form) setUp(form);
});
