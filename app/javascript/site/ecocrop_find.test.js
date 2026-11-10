import { describe, it, expect, beforeEach, vi } from 'vitest';
import { searchRecords, showRecords, setUpFind } from './ecocrop_find';

const carrot = {
  id: 5,
  scientific_name: 'Daucus carota',
  common_names: ['carrot', 'karotte'],
  details: { family: 'Apiaceae' },
  crops: ['baby carrot']
};

describe('searchRecords', () => {
  it('asks the search endpoint for the term', async () => {
    const fetcher = vi.fn(() => Promise.resolve({ json: () => Promise.resolve([]) }));
    await searchRecords('wild carrot', '/admin/ecocrop/search.json', fetcher);
    expect(fetcher.mock.calls[0][0]).toBe('/admin/ecocrop/search.json?q=wild%20carrot');
  });
});

describe('showRecords', () => {
  let list;

  beforeEach(() => {
    document.body.innerHTML = '<ul id="results"></ul>';
    list = document.getElementById('results');
  });

  it('shows the scientific name and common names', () => {
    showRecords(list, [carrot], () => {});
    expect(list.textContent).toContain('Daucus carotacarrot, karotte');
  });

  it('says which crops a record is already linked to', () => {
    showRecords(list, [carrot], () => {}, { linkedTo: 'Already linked to __CROPS__' });
    expect(list.textContent).toContain('Already linked to baby carrot');
  });

  it('shows names as text, not markup', () => {
    showRecords(list, [{ ...carrot, scientific_name: '<b>x</b>' }], () => {});
    expect(list.querySelector('b')).toBeNull();
  });

  it('hands the chosen record on', () => {
    const onChoose = vi.fn();
    showRecords(list, [carrot], onChoose);
    list.querySelector('button').click();
    expect(onChoose).toHaveBeenCalledWith(carrot);
  });

  it('says when there are none', () => {
    showRecords(list, [], () => {}, { none: 'No records' });
    expect(list.textContent).toBe('No records');
  });
});

describe('setUpFind', () => {
  const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
  let fetcher;

  beforeEach(() => {
    document.body.innerHTML = `
      <button id="open" data-ecocrop-find="9" data-ecocrop-crop-name="carrot" data-ecocrop-existing-names='["carrot"]'>find</button>
      <div id="modal" data-search-url="/s.json" data-link-url="/admin/ecocrop/__ID__/link" data-labels='{"family":"Family"}'
           data-confirm="Link __CROP__ to __RECORD__?" data-none="None" data-linked-to="Linked to __CROPS__">
        <div id="ecocrop-find-search-panel"><input id="ecocrop-find-search"><ul id="ecocrop-find-results"></ul></div>
        <div id="ecocrop-find-confirm" class="d-none">
          <div id="ecocrop-find-details"></div><p id="ecocrop-find-confirm-text"></p>
          <fieldset id="ecocrop-find-names" class="d-none"><div class="ecocrop-names-list"></div></fieldset>
          <button id="ecocrop-find-back"></button>
        </div>
        <form id="ecocrop-find-form"><input id="ecocrop-find-crop-id" name="crop_id" value="9"></form>
        <button id="ecocrop-find-confirm-yes" class="d-none"></button>
      </div>`;
    fetcher = vi.fn(() => Promise.resolve({ json: () => Promise.resolve([carrot]) }));
    document.getElementById('ecocrop-find-form').submit = vi.fn();
    setUpFind(document.getElementById('modal'), fetcher);
  });

  it('searches for the crop name when opened', async () => {
    document.getElementById('open').click();
    await flush();
    expect(fetcher.mock.calls[0][0]).toBe('/s.json?q=carrot');
  });

  it('asks to confirm the record chosen', async () => {
    document.getElementById('open').click();
    await flush();
    document.querySelector('#ecocrop-find-results button').click();
    expect(document.getElementById('ecocrop-find-confirm-text').textContent).toBe('Link carrot to Daucus carota?');
  });

  it('offers the names the crop lacks', async () => {
    document.getElementById('open').click();
    await flush();
    document.querySelector('#ecocrop-find-results button').click();
    expect(document.querySelector('#ecocrop-find-names input').value).toBe('karotte');
  });

  it('links to the record only once confirmed', async () => {
    document.getElementById('open').click();
    await flush();
    document.querySelector('#ecocrop-find-results button').click();
    document.getElementById('ecocrop-find-confirm-yes').click();
    expect(document.getElementById('ecocrop-find-form').getAttribute('action')).toBe('/admin/ecocrop/5/link');
  });
});
