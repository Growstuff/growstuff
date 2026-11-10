import { describe, it, expect, beforeEach, vi } from 'vitest';
import { searchCrops, showResults, choose, confirmMessage, exactFirst, setUp } from './ecocrop_link';

describe('searchCrops', () => {
  it('asks the search endpoint for the term', async () => {
    const fetcher = vi.fn(() => Promise.resolve({ json: () => Promise.resolve([{ id: 1, name: 'tomato' }]) }));
    await searchCrops('tom ato', '/crops/search.json', fetcher);
    expect(fetcher.mock.calls[0][0]).toBe('/crops/search.json?term=tom%20ato');
  });
});

describe('showResults', () => {
  let list;

  beforeEach(() => {
    document.body.innerHTML = '<ul id="results"></ul>';
    list = document.getElementById('results');
  });

  it('lists a button for each crop', () => {
    showResults(list, [{ id: 1, name: 'tomato' }, { id: 2, name: 'tomatillo' }], () => {});
    expect(list.querySelectorAll('button')).toHaveLength(2);
  });

  it('names the alternate name that matched', () => {
    showResults(list, [{ id: 1, name: 'tomato', matched_alternate_name: 'love apple' }], () => {});
    expect(list.textContent).toBe('tomato (love apple)');
  });

  it('shows crop names as text, not markup', () => {
    showResults(list, [{ id: 1, name: '<b>tomato</b>' }], () => {});
    expect(list.querySelector('b')).toBeNull();
  });

  it('hands the chosen crop on', () => {
    const onChoose = vi.fn();
    showResults(list, [{ id: 7, name: 'tomato' }], onChoose);
    list.querySelector('button').click();
    expect(onChoose).toHaveBeenCalledWith({ id: 7, name: 'tomato' });
  });

  it('says when there are none', () => {
    showResults(list, [], () => {}, 'No crops found');
    expect(list.textContent).toBe('No crops found');
  });
});

describe('choose', () => {
  let modal;
  let form;

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="modal" data-link-url="/admin/ecocrop/__ID__/link">
        <form id="ecocrop-link-form"><input id="ecocrop-link-crop-id" name="crop_id"></form>
      </div>`;
    modal = document.getElementById('modal');
    form = document.getElementById('ecocrop-link-form');
    form.submit = vi.fn();
  });

  it('points the form at the record', () => {
    choose(modal, '42', { id: 7 });
    expect(form.getAttribute('action')).toBe('/admin/ecocrop/42/link');
  });

  it('sets the crop', () => {
    choose(modal, '42', { id: 7 });
    expect(document.getElementById('ecocrop-link-crop-id').value).toBe('7');
  });

  it('submits the form', () => {
    choose(modal, '42', { id: 7 });
    expect(form.submit).toHaveBeenCalled();
  });
});

describe('exactFirst', () => {
  const crops = [{ name: 'acorn squash' }, { name: 'Squash' }, { name: 'turban squash' }, { name: 'squash' }];

  it('puts exact matches first, ignoring case', () => {
    expect(exactFirst(crops, 'squash').map((crop) => crop.name)).toEqual(['Squash', 'squash', 'acorn squash', 'turban squash']);
  });

  it('leaves the order alone without an exact match', () => {
    expect(exactFirst(crops, 'marrow')).toEqual(crops);
  });
});

describe('confirmMessage', () => {
  it('names the crop and the record', () => {
    expect(confirmMessage('Link __CROP__ to __RECORD__?', { name: 'tomato' }, 'Lycopersicon esculentum'))
      .toBe('Link tomato to Lycopersicon esculentum?');
  });
});

describe('setUp', () => {
  const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
  let fetcher;

  const respondWith = (crops) => {
    fetcher = vi.fn(() => Promise.resolve({ json: () => Promise.resolve(crops) }));
    setUp(document.getElementById('modal'), fetcher);
  };

  beforeEach(() => {
    document.body.innerHTML = `
      <button id="name" data-ecocrop-link="42" data-ecocrop-name="Lycopersicon esculentum" data-ecocrop-term="tomato">tomato</button>
      <div id="modal" data-search-url="/crops/search.json" data-link-url="/admin/ecocrop/__ID__/link"
           data-confirm="Link __CROP__ to __RECORD__?" data-none="None">
        <p id="ecocrop-link-name"></p>
        <div id="ecocrop-link-search-panel"><input id="ecocrop-link-search"><ul id="ecocrop-link-results"></ul></div>
        <div id="ecocrop-link-confirm" class="d-none">
          <p id="ecocrop-link-confirm-text"></p>
          <button id="ecocrop-link-confirm-yes"></button><button id="ecocrop-link-confirm-back"></button>
        </div>
        <form id="ecocrop-link-form"><input id="ecocrop-link-crop-id"></form>
      </div>`;
    document.getElementById('ecocrop-link-form').submit = vi.fn();
  });

  it('searches for the common name clicked', async () => {
    respondWith([]);
    document.getElementById('name').click();
    await flush();
    expect(fetcher.mock.calls[0][0]).toBe('/crops/search.json?term=tomato');
  });

  it('asks to confirm when one crop is found', async () => {
    respondWith([{ id: 7, name: 'tomato' }]);
    document.getElementById('name').click();
    await flush();
    expect(document.getElementById('ecocrop-link-confirm-text').textContent).toBe('Link tomato to Lycopersicon esculentum?');
  });

  it('lists the crops when several are found', async () => {
    respondWith([{ id: 7, name: 'tomato' }, { id: 8, name: 'tomatillo' }]);
    document.getElementById('name').click();
    await flush();
    expect(document.querySelectorAll('#ecocrop-link-results button')).toHaveLength(2);
  });

  it('shows the confirm button once a crop is chosen', async () => {
    respondWith([{ id: 7, name: 'tomato' }]);
    document.getElementById('name').click();
    await flush();
    expect(document.getElementById('ecocrop-link-confirm-yes').classList.contains('d-none')).toBe(false);
  });

  it('links the crop only once confirmed', async () => {
    respondWith([{ id: 7, name: 'tomato' }]);
    document.getElementById('name').click();
    await flush();
    document.getElementById('ecocrop-link-confirm-yes').click();
    expect(document.getElementById('ecocrop-link-crop-id').value).toBe('7');
  });
});
