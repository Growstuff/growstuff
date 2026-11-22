import { describe, it, expect, beforeEach, vi } from 'vitest';
import { searchCrops, showResults, choose, confirmMessage, exactFirst, parseNames, renderNames, hasNote, renderDetails, parseDetails, wikipediaUrl, setUp } from './ecocrop_link';

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

describe('parseNames', () => {
  it('reads a list', () => {
    expect(parseNames('["carrot","karotte"]')).toEqual(['carrot', 'karotte']);
  });

  it('is empty for nothing sensible', () => {
    expect(parseNames('nonsense')).toEqual([]);
  });
});

describe('renderDetails', () => {
  let container;

  beforeEach(() => {
    document.body.innerHTML = '<div id="details"></div>';
    container = document.getElementById('details');
  });

  it('names the scientific name', () => {
    renderDetails(container, { scientific_name: 'Daucus carota L.' });
    expect(container.querySelector('p').textContent).toBe('Daucus carota L.');
  });

  it('lists all the common names', () => {
    renderDetails(container, { common_names: ['carrot', 'karotte'] }, { common_names: 'Common names' });
    expect(container.querySelector('dd').textContent).toBe('carrot, karotte');
  });

  it('labels each detail', () => {
    renderDetails(container, { family: 'Apiaceae' }, { family: 'Family' });
    expect(container.querySelector('dt').textContent).toBe('Family');
  });

  it('leaves out what there is none of', () => {
    renderDetails(container, { scientific_name: 'Daucus carota', category: '' });
    expect(container.querySelector('dt')).toBeNull();
  });

  it('shows names as text, not markup', () => {
    renderDetails(container, { common_names: ['<b>carrot</b>'] });
    expect(container.querySelector('b')).toBeNull();
  });
});

describe('parseDetails', () => {
  it('reads an object', () => {
    expect(parseDetails('{"family":"Apiaceae"}')).toEqual({ family: 'Apiaceae' });
  });

  it('is empty for nonsense', () => {
    expect(parseDetails('[1')).toEqual({});
  });
});

describe('hasNote', () => {
  it('is true for a note in brackets', () => {
    expect(hasNote('kukama (Tuvalu)')).toBe(true);
  });

  it('is false for a plain name', () => {
    expect(hasNote('carrot')).toBe(false);
  });
});

describe('wikipediaUrl', () => {
  it('uses the scientific name as the title', () => {
    expect(wikipediaUrl('Daucus carota')).toBe('https://en.wikipedia.org/wiki/Daucus_carota');
  });
});

describe('renderNames', () => {
  let fieldset;

  beforeEach(() => {
    document.body.innerHTML = '<fieldset id="names" class="d-none"><div class="ecocrop-names-list"></div></fieldset>';
    fieldset = document.getElementById('names');
  });

  it('ticks a box for each name', () => {
    renderNames(fieldset, ['carrot', 'karotte']);
    expect(fieldset.querySelectorAll('input:checked')).toHaveLength(2);
  });

  it('does not tick a name with a note in brackets', () => {
    renderNames(fieldset, ['carrot', 'brocoli (French)']);
    expect([...fieldset.querySelectorAll('input')].map((box) => box.checked)).toEqual([true, false]);
  });

  it('still offers a name with a note in brackets', () => {
    renderNames(fieldset, ['brocoli (French)']);
    expect(fieldset.querySelectorAll('input')).toHaveLength(1);
  });

  it('skips names ignoring case', () => {
    renderNames(fieldset, ['carrot', 'karotte'], ['Carrot']);
    expect(fieldset.querySelector('input').value).toBe('karotte');
  });

  it('shows the fieldset when there are names', () => {
    renderNames(fieldset, ['carrot']);
    expect(fieldset.classList.contains('d-none')).toBe(false);
  });

  it('hides the fieldset when there are none', () => {
    renderNames(fieldset, ['carrot'], ['carrot']);
    expect(fieldset.classList.contains('d-none')).toBe(true);
  });

  it('attaches the boxes to a form', () => {
    renderNames(fieldset, ['carrot'], [], 'the-form');
    expect(fieldset.querySelector('input').getAttribute('form')).toBe('the-form');
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
      <button id="name" data-ecocrop-link="42" data-ecocrop-name="Lycopersicon esculentum" data-ecocrop-term="tomato"
              data-ecocrop-names='["tomato","tomate"]'>tomato</button>
      <button id="copy" data-ecocrop-link="42" data-ecocrop-name="Lycopersicon esculentum" data-ecocrop-names='["tomato","tomate"]'
              data-ecocrop-crop-id="7" data-ecocrop-crop-name="tomato">copy</button>
      <div id="modal" data-search-url="/crops/search.json" data-link-url="/admin/ecocrop/__ID__/link"
           data-confirm="Link __CROP__ to __RECORD__?" data-none="None">
        <div id="ecocrop-link-details"></div>
        <div id="ecocrop-link-search-panel"><input id="ecocrop-link-search"><ul id="ecocrop-link-results"></ul></div>
        <div id="ecocrop-link-confirm" class="d-none">
          <p id="ecocrop-link-confirm-text"></p>
          <fieldset id="ecocrop-link-names" class="d-none"><div class="ecocrop-names-list"></div></fieldset>
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

  it('offers the other common names to copy', async () => {
    respondWith([{ id: 7, name: 'tomato' }]);
    document.getElementById('name').click();
    await flush();
    expect(document.querySelector('#ecocrop-link-names input').value).toBe('tomate');
  });

  it('goes straight to confirming for a crop already chosen', () => {
    respondWith([]);
    document.getElementById('copy').click();
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
