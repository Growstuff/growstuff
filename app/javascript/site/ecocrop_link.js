// The crop wrangler's dialogs for EcoCrop records. A row's button with data-ecocrop-link (the record's
// id) opens the link dialog. A button that also has data-ecocrop-term (a common name) starts with that
// search already run, and one with data-ecocrop-crop-id skips the search for that crop. Choosing a crop
// asks for confirmation, with the record's common names to tick for copying to the crop as alternate
// names, before the form is posted to that record's link URL. A button with data-ecocrop-create opens
// the dialog that makes a new crop from the record.
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

export function parseNames(json) {
  try {
    const names = JSON.parse(json || '[]');
    return Array.isArray(names) ? names : [];
  } catch (error) {
    return [];
  }
}

export function parseDetails(json) {
  try {
    const details = JSON.parse(json || '{}');
    return details && typeof details === 'object' && !Array.isArray(details) ? details : {};
  } catch (error) {
    return {};
  }
}

// What the record is, so a wrangler can tell which one they are linking: the scientific name, then its common
// names and what kind of plant it is. The text is set as text, never as HTML.
export function renderDetails(container, details, labels = {}) {
  container.replaceChildren();
  if (details.scientific_name) {
    const title = document.createElement('p');
    title.className = 'fw-bold fst-italic mb-1';
    title.textContent = details.scientific_name;
    container.append(title);
  }
  const list = document.createElement('dl');
  list.className = 'row mb-0 small';
  [['common_names', (details.common_names || []).join(', ')], ['family', details.family],
    ['category', details.category], ['life_form', details.life_form]].forEach(([key, value]) => {
    if (!value) return;
    const term = document.createElement('dt');
    term.className = 'col-sm-4';
    term.textContent = labels[key] || key;
    const description = document.createElement('dd');
    description.className = 'col-sm-8 mb-1';
    description.textContent = value;
    list.append(term, description);
  });
  container.append(list);
}

// A tick for each name, all ticked, apart from any in skip (compared ignoring case). The ticks belong to the form
// with that id, so they can sit outside it. The fieldset is hidden when there is nothing to offer.
export function renderNames(fieldset, names, skip = [], formId = null) {
  const list = fieldset.querySelector('.ecocrop-names-list');
  const skipped = skip.filter(Boolean).map((name) => name.toLowerCase());
  list.replaceChildren();
  names.filter((name) => !skipped.includes(name.toLowerCase())).forEach((name, index) => {
    const wrapper = document.createElement('div');
    wrapper.className = 'form-check';
    const box = document.createElement('input');
    box.type = 'checkbox';
    box.className = 'form-check-input';
    box.name = 'names[]';
    box.value = name;
    box.checked = true;
    box.id = `${fieldset.id}-${index}`;
    if (formId) box.setAttribute('form', formId);
    const label = document.createElement('label');
    label.className = 'form-check-label';
    label.htmlFor = box.id;
    label.textContent = name;
    wrapper.append(box, label);
    list.append(wrapper);
  });
  fieldset.classList.toggle('d-none', list.children.length === 0);
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
  let recordNames = [];
  let chosen = null;
  let timer = null;

  const ask = (crop) => {
    chosen = crop;
    modal.querySelector('#ecocrop-link-confirm-text').textContent = confirmMessage(modal.dataset.confirm, crop, recordName);
    renderNames(modal.querySelector('#ecocrop-link-names'), recordNames, [crop.name, crop.matched_alternate_name], 'ecocrop-link-form');
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
    recordNames = parseNames(button.dataset.ecocropNames);
    renderDetails(modal.querySelector('#ecocrop-link-details'), parseDetails(button.dataset.ecocropDetails), parseDetails(modal.dataset.labels));
    input.value = button.dataset.ecocropTerm || '';
    list.replaceChildren();
    if (button.dataset.ecocropCropId) {
      ask({ id: button.dataset.ecocropCropId, name: button.dataset.ecocropCropName });
      return;
    }
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

// A guess at the English Wikipedia page for a species, for the wrangler to check: the scientific name as the title.
export function wikipediaUrl(scientificName) {
  const title = scientificName.trim().replace(/\s+/g, '_');
  return `https://en.wikipedia.org/wiki/${encodeURIComponent(title)}`;
}

// The dialog that makes a crop from a record: the name to give it, chosen from the common names or typed,
// and the other common names to keep as its alternate names.
export function setUpCreate(modal) {
  const form = modal.querySelector('#ecocrop-create-form');
  const nameInput = modal.querySelector('#ecocrop-create-crop-name');
  const options = modal.querySelector('#ecocrop-create-name-options');

  document.addEventListener('click', (event) => {
    const button = event.target.closest('[data-ecocrop-create]');
    if (!button) return;
    const names = parseNames(button.dataset.ecocropNames);
    form.action = modal.dataset.createUrl.replace('__ID__', button.dataset.ecocropCreate);
    renderDetails(modal.querySelector('#ecocrop-create-details'), parseDetails(button.dataset.ecocropDetails), parseDetails(modal.dataset.labels));
    nameInput.value = names[0] || '';
    modal.querySelector('#ecocrop-create-wikipedia-url').value = wikipediaUrl(button.dataset.ecocropName);
    options.replaceChildren(...names.map((name) => {
      const option = document.createElement('option');
      option.value = name;
      return option;
    }));
    renderNames(modal.querySelector('#ecocrop-create-names'), names, [names[0]]);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  const modal = document.getElementById('ecocrop-link-modal');
  if (modal) setUp(modal);
  const createModal = document.getElementById('ecocrop-create-modal');
  if (createModal) setUpCreate(createModal);
});
