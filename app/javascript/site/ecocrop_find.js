// The dialog on a crop's page that finds its EcoCrop record. A button with data-ecocrop-find opens it, already
// searching for the crop's name. Choosing a record asks for confirmation, with the record's common names to tick for
// copying to the crop as alternate names, before the form is posted to that record's link URL.
import { parseNames, parseDetails, renderNames, renderDetails, confirmMessage } from './ecocrop_link';

const DEBOUNCE_MS = 250;

export function searchRecords(term, searchUrl, fetcher = fetch) {
  const url = `${searchUrl}${searchUrl.includes('?') ? '&' : '?'}q=${encodeURIComponent(term)}`;
  return fetcher(url, { headers: { Accept: 'application/json' } }).then((response) => response.json());
}

// One choice per record: the scientific name, its common names, and which crops it is already linked to. The text
// is set as text, never as HTML.
export function showRecords(list, records, onChoose, { none = '', linkedTo = '' } = {}) {
  list.replaceChildren();
  if (records.length === 0 && none) {
    const item = document.createElement('li');
    item.className = 'list-group-item text-muted';
    item.textContent = none;
    list.append(item);
    return;
  }
  records.forEach((record) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'list-group-item list-group-item-action';
    const name = document.createElement('em');
    name.textContent = record.scientific_name;
    const common = document.createElement('small');
    common.className = 'd-block text-muted';
    common.textContent = (record.common_names || []).slice(0, 5).join(', ');
    button.append(name, common);
    if (record.crops && record.crops.length) {
      const linked = document.createElement('small');
      linked.className = 'd-block text-muted';
      linked.textContent = linkedTo.replace('__CROPS__', record.crops.join(', '));
      button.append(linked);
    }
    button.addEventListener('click', () => onChoose(record));
    list.append(button);
  });
}

export function setUpFind(modal, fetcher = fetch) {
  const input = modal.querySelector('#ecocrop-find-search');
  const list = modal.querySelector('#ecocrop-find-results');
  const searchPanel = modal.querySelector('#ecocrop-find-search-panel');
  const confirmPanel = modal.querySelector('#ecocrop-find-confirm');
  const yes = modal.querySelector('#ecocrop-find-confirm-yes');
  const form = modal.querySelector('#ecocrop-find-form');
  let cropName = '';
  let existingNames = [];
  let chosen = null;
  let timer = null;

  const showConfirm = (confirming) => {
    searchPanel.classList.toggle('d-none', confirming);
    confirmPanel.classList.toggle('d-none', !confirming);
    yes.classList.toggle('d-none', !confirming);
  };

  const ask = (record) => {
    chosen = record;
    renderDetails(modal.querySelector('#ecocrop-find-details'), { ...record.details, scientific_name: record.scientific_name },
      parseDetails(modal.dataset.labels));
    modal.querySelector('#ecocrop-find-confirm-text').textContent = confirmMessage(modal.dataset.confirm, { name: cropName }, record.scientific_name);
    renderNames(modal.querySelector('#ecocrop-find-names'), record.common_names || [], existingNames, 'ecocrop-find-form');
    showConfirm(true);
  };

  const run = () => {
    const term = input.value.trim();
    if (term.length < 2) { list.replaceChildren(); return Promise.resolve(); }
    return searchRecords(term, modal.dataset.searchUrl, fetcher)
      .then((records) => showRecords(list, records, ask, { none: modal.dataset.none, linkedTo: modal.dataset.linkedTo }));
  };

  document.addEventListener('click', (event) => {
    const button = event.target.closest('[data-ecocrop-find]');
    if (!button) return;
    cropName = button.dataset.ecocropCropName;
    existingNames = parseNames(button.dataset.ecocropExistingNames);
    input.value = cropName;
    list.replaceChildren();
    showConfirm(false);
    run();
  });

  yes.addEventListener('click', () => {
    form.action = modal.dataset.linkUrl.replace('__ID__', chosen.id);
    form.submit();
  });
  modal.querySelector('#ecocrop-find-back').addEventListener('click', () => showConfirm(false));
  modal.addEventListener('shown.bs.modal', () => input.focus());
  input.addEventListener('input', () => {
    clearTimeout(timer);
    timer = setTimeout(run, DEBOUNCE_MS);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  const modal = document.getElementById('ecocrop-find-modal');
  if (modal) setUpFind(modal);
});
