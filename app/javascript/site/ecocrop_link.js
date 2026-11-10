// The crop wrangler's dialog for linking an EcoCrop record to a crop. A row's button with
// data-ecocrop-link (the record's id) opens it. A button that also has data-ecocrop-term (a common
// name) starts with that search already run. Choosing a crop asks for confirmation before the
// dialog's form is posted to that record's link URL.
const DEBOUNCE_MS = 250;

export function searchCrops(term, searchUrl, fetcher = fetch) {
  const url = `${searchUrl}${searchUrl.includes('?') ? '&' : '?'}term=${encodeURIComponent(term)}`;
  return fetcher(url, { headers: { Accept: 'application/json' } }).then((response) => response.json());
}

// Crops named exactly like the term come first, ignoring case; the rest keep the order they came in.
export function exactFirst(crops, term) {
  const wanted = term.trim().toLowerCase();
  const exact = crops.filter((crop) => crop.name.trim().toLowerCase() === wanted);
  return exact.concat(crops.filter((crop) => !exact.includes(crop)));
}

// One choice per crop. The text is set as text, never as HTML, because crop names are typed by members.
export function showResults(list, crops, onChoose, noneText = '') {
  list.replaceChildren();
  if (crops.length === 0 && noneText) {
    const item = document.createElement('li');
    item.className = 'list-group-item text-muted';
    item.textContent = noneText;
    list.append(item);
    return;
  }
  crops.forEach((crop) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'list-group-item list-group-item-action';
    button.textContent = crop.matched_alternate_name ? `${crop.name} (${crop.matched_alternate_name})` : crop.name;
    button.addEventListener('click', () => onChoose(crop));
    list.append(button);
  });
}

export function confirmMessage(template, crop, recordName) {
  return template.replace('__CROP__', crop.name).replace('__RECORD__', recordName);
}

export function choose(modal, recordId, crop) {
  const form = modal.querySelector('#ecocrop-link-form');
  form.action = modal.dataset.linkUrl.replace('__ID__', recordId);
  form.querySelector('#ecocrop-link-crop-id').value = crop.id;
  form.submit();
}

function showPanel(modal, confirming) {
  modal.querySelector('#ecocrop-link-search-panel').classList.toggle('d-none', confirming);
  modal.querySelector('#ecocrop-link-confirm').classList.toggle('d-none', !confirming);
  modal.querySelector('#ecocrop-link-confirm-yes').classList.toggle('d-none', !confirming);
}

export function setUp(modal, fetcher = fetch) {
  const input = modal.querySelector('#ecocrop-link-search');
  const list = modal.querySelector('#ecocrop-link-results');
  let recordId = null;
  let recordName = '';
  let chosen = null;
  let timer = null;

  const ask = (crop) => {
    chosen = crop;
    modal.querySelector('#ecocrop-link-confirm-text').textContent = confirmMessage(modal.dataset.confirm, crop, recordName);
    showPanel(modal, true);
  };

  const run = () => {
    const term = input.value.trim();
    if (term.length < 2) { list.replaceChildren(); return Promise.resolve(); }
    return searchCrops(term, modal.dataset.searchUrl, fetcher).then((found) => {
      const crops = exactFirst(found, term);
      if (crops.length === 1) ask(crops[0]);
      else showResults(list, crops, ask, modal.dataset.none);
    });
  };

  document.addEventListener('click', (event) => {
    const button = event.target.closest('[data-ecocrop-link]');
    if (!button) return;
    recordId = button.dataset.ecocropLink;
    recordName = button.dataset.ecocropName;
    modal.querySelector('#ecocrop-link-name').textContent = recordName;
    input.value = button.dataset.ecocropTerm || '';
    list.replaceChildren();
    showPanel(modal, false);
    run();
  });

  modal.querySelector('#ecocrop-link-confirm-yes').addEventListener('click', () => choose(modal, recordId, chosen));
  modal.querySelector('#ecocrop-link-confirm-back').addEventListener('click', () => {
    showPanel(modal, false);
    run();
  });

  modal.addEventListener('shown.bs.modal', () => input.focus());

  input.addEventListener('input', () => {
    clearTimeout(timer);
    timer = setTimeout(run, DEBOUNCE_MS);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  const modal = document.getElementById('ecocrop-link-modal');
  if (modal) setUp(modal);
});
