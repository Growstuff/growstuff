import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';

const CELEBRATIONS = {
  levels: {
    one: {lead: 'Nice one!', note: 'The snail is impressed.'},
    two: {lead: 'Two in a row!', note: 'The snail is quick.'},
    three: {lead: 'Hat-trick!', note: 'The snail stopped.'},
    many: {lead: 'On a roll!', note: 'The snails are called.'},
  },
  slow: 'Slow and steady.',
  crossed_off: 'Crossed off "%{name}"',
  undo: 'Undo',
  done: {one: '1 job done this week.', other: '%{count} jobs done this week.'},
};

const row = (id, name, extra = '') => `
  <div class="notepad-job" draggable="true" data-url="/jobs/${name.toLowerCase()}" data-id="${id}">
    <form class="notepad-tick" action="/jobs/${name.toLowerCase()}" method="post">
      <input type="hidden" name="_method" value="patch">
      <input type="hidden" name="job[finished]" value="1">
      <button type="submit" class="notepad-box"></button>
    </form>
    <span class="notepad-name" data-edit-label="Job name">${name}</span>
    <span class="notepad-edit-hint" hidden>Enter to save, Esc to cancel</span>
    ${extra}
    <div class="notepad-menu"><a href="/jobs/${name.toLowerCase()}/edit" data-notepad-edit="true">Edit</a></div>
  </div>`;

const page = () => `
  <meta name="csrf-token" content="token-123">
  <div class="notepad">
    <form class="notepad-add" action="/jobs" method="post"
          data-kinds='{"planting":"Planting","seed":"Seeds","crop":"Crop"}' data-suggestions-url="/jobs/suggestions">
      <input type="text" name="job[name]">
      <input type="submit" value="Add" data-saving-label="Adding…">
      <input type="hidden" id="notepad-jobbable-type" name="job[jobbable_type]">
      <input type="hidden" id="notepad-jobbable-id" name="job[jobbable_id]">
      <ul id="notepad-suggestions" hidden></ul>
    </form>
    <div id="notepad-link" hidden><span class="notepad-link-text"></span><button type="button">x</button></div>
    <p id="notepad-add-saving" hidden data-template="Adding “%{name}”…">
      <span class="notepad-spinner"></span><span class="notepad-add-saving-text"></span>
    </p>
    <p id="notepad-add-failed" hidden>That job may not have been added.</p>
    <div id="notepad-groups" data-celebrations='${JSON.stringify(CELEBRATIONS)}'>
      <div class="notepad-group" data-drop="2026-10-23"><h2>Today</h2>${row(1, 'Water')}</div>
      <div class="notepad-group" data-drop="none"><h2>Some day</h2><p class="notepad-drop-hint">Drag a job here.</p></div>
      <div class="notepad-group"><h2>Overdue</h2>${row(2, 'Weed')}</div>
    </div>
    <span id="notepad-snail-caption">Slow and steady.</span>
  </div>`;

const answer = (html = '<div class="notepad-group" data-drop="2026-10-23"><h2>Today</h2></div>', done = '0') => ({
  ok: true,
  headers: {get: () => done},
  text: () => Promise.resolve(html),
});

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

// The script wires itself up when the page has loaded. Import it fresh for each
// test and run that step by hand, so earlier tests' wiring doesn't pile up.
const start = async () => {
  vi.resetModules();
  const listen = vi.spyOn(document, 'addEventListener').mockImplementation(() => {});
  await import('./job_notepad');
  const handlers = listen.mock.calls.filter(([name]) => name === 'DOMContentLoaded').map(([, handler]) => handler);
  listen.mockRestore();
  handlers.forEach((handler) => handler());
};

const submit = (form) => form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true}));

const dragEvent = (type) => {
  const event = new Event(type, {bubbles: true, cancelable: true});
  event.dataTransfer = {setData: vi.fn(), effectAllowed: ''};
  return event;
};

let fetchMock;

beforeEach(() => {
  document.body.innerHTML = page();
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
});

afterEach(() => {
  document.body.innerHTML = '';
});

describe('a notepad on a garden\'s page', () => {
  it('says which garden every request is for', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    document.getElementById('notepad-groups').dataset.gardenId = '7';
    await start();
    document.querySelector('.notepad-add input[type="text"]').value = 'Net the berries';
    submit(document.querySelector('.notepad-add'));

    expect(fetchMock.mock.calls[0][1].body.get('garden_id')).toBe('7');
  });

  it('says nothing of a garden on the jobs page', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    document.querySelector('.notepad-add input[type="text"]').value = 'Net the berries';
    submit(document.querySelector('.notepad-add'));

    expect(fetchMock.mock.calls[0][1].body.has('garden_id')).toBe(false);
  });
});

describe('adding a job', () => {
  const type = (text) => {
    document.querySelector('.notepad-add input[type="text"]').value = text;
  };

  it('shows that the job is on its way', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    type('Sow the peas');
    submit(document.querySelector('.notepad-add'));

    expect(document.getElementById('notepad-add-saving').hidden).toBe(false);
    expect(document.querySelector('.notepad-add-saving-text').textContent).toBe('Adding “Sow the peas”…');
  });

  it('holds the button, saying Adding, while it is sent', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    type('Sow the peas');
    submit(document.querySelector('.notepad-add'));

    const button = document.querySelector('.notepad-add input[type="submit"]');
    expect([button.disabled, button.value]).toEqual([true, 'Adding…']);
  });

  it('does not send a second time while the first is on its way', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    type('Sow the peas');
    submit(document.querySelector('.notepad-add'));
    submit(document.querySelector('.notepad-add'));

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('sends the job with the page token, as an AJAX request', async () => {
    fetchMock.mockResolvedValue(answer());
    await start();
    type('Sow the peas');
    submit(document.querySelector('.notepad-add'));

    const [url, options] = fetchMock.mock.calls[0];
    expect([url, options.headers['X-CSRF-Token'], options.headers['X-Requested-With']]).toEqual(['http://localhost:3000/jobs', 'token-123', 'XMLHttpRequest']);
    expect(options.body.get('job[name]')).toBe('Sow the peas');
  });

  it('clears the box and the saving line once it has landed', async () => {
    fetchMock.mockResolvedValue(answer('<div class="notepad-group"><h2>Today</h2></div>'));
    await start();
    type('Sow the peas');
    submit(document.querySelector('.notepad-add'));
    await flush();

    expect(document.querySelector('.notepad-add input[type="text"]').value).toBe('');
    expect(document.getElementById('notepad-add-saving').hidden).toBe(true);
    expect(document.querySelector('.notepad-add input[type="submit"]').disabled).toBe(false);
  });

  it('shows the groups the server sends back', async () => {
    fetchMock.mockResolvedValue(answer('<div class="notepad-group" id="fresh"><h2>Today</h2></div>'));
    await start();
    type('Sow the peas');
    submit(document.querySelector('.notepad-add'));
    await flush();

    expect(document.querySelector('#notepad-groups #fresh')).not.toBeNull();
  });

  it('leaves what was typed while it was on its way', async () => {
    let finish;
    fetchMock.mockReturnValue(new Promise((resolve) => { finish = resolve; }));
    await start();
    type('Sow the peas');
    submit(document.querySelector('.notepad-add'));
    type('Water the beds');
    finish(answer());
    await flush();

    expect(document.querySelector('.notepad-add input[type="text"]').value).toBe('Water the beds');
  });

  it('ignores an empty box', async () => {
    await start();
    type('   ');
    submit(document.querySelector('.notepad-add'));

    expect(fetchMock).not.toHaveBeenCalled();
  });

  describe('when it fails', () => {
    beforeEach(async () => {
      fetchMock.mockResolvedValue({ok: false, status: 500, headers: {get: () => null}, text: () => Promise.resolve('')});
      await start();
      type('Sow the peas');
      submit(document.querySelector('.notepad-add'));
      await flush();
    });

    it('says the job may not have been added', () => {
      expect(document.getElementById('notepad-add-failed').hidden).toBe(false);
    });

    it('keeps the job in the box', () => {
      expect(document.querySelector('.notepad-add input[type="text"]').value).toBe('Sow the peas');
    });

    it('lets it be tried again, and stops saying it is on its way', () => {
      expect(document.querySelector('.notepad-add input[type="submit"]').disabled).toBe(false);
      expect(document.getElementById('notepad-add-saving').hidden).toBe(true);
    });

    it('does not send it again by itself', () => {
      expect(fetchMock).toHaveBeenCalledTimes(1);
    });
  });
});

describe('dropping a job on a day', () => {
  const drop = (from, to) => {
    from.dispatchEvent(dragEvent('dragstart'));
    to.dispatchEvent(dragEvent('drop'));
  };
  const groupFor = (day) => document.querySelector(`.notepad-group[data-drop="${day}"]`);

  it('shows the job in its new place at once, marked as saving', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    const water = document.querySelector('.notepad-job[data-id="2"]');
    drop(water, groupFor('none'));

    expect(water.parentElement).toBe(groupFor('none'));
    expect(water.classList.contains('saving')).toBe(true);
  });

  it('takes away the hint for an empty group', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    drop(document.querySelector('.notepad-job[data-id="2"]'), groupFor('none'));

    expect(groupFor('none').querySelector('.notepad-drop-hint')).toBeNull();
  });

  it('asks for the group\'s day', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    drop(document.querySelector('.notepad-job[data-id="2"]'), groupFor('2026-10-23'));

    const [url, options] = fetchMock.mock.calls[0];
    expect([url, options.body.get('_method'), options.body.get('job[due_date]')]).toEqual(['/jobs/weed', 'patch', '2026-10-23']);
  });

  it('asks for no day when dropped on Some day', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    drop(document.querySelector('.notepad-job[data-id="1"]'), groupFor('none'));

    expect(fetchMock.mock.calls[0][1].body.get('job[due_date]')).toBe('');
  });

  it('shows the groups the server sends back', async () => {
    fetchMock.mockResolvedValue(answer('<div class="notepad-group" id="fresh"></div>'));
    await start();
    drop(document.querySelector('.notepad-job[data-id="2"]'), groupFor('none'));
    await flush();

    expect(document.querySelector('#notepad-groups #fresh')).not.toBeNull();
    expect(document.querySelector('.saving')).toBeNull();
  });

  it('does nothing when dropped where jobs cannot go', async () => {
    await start();
    const water = document.querySelector('.notepad-job[data-id="1"]');
    drop(water, document.querySelector('.notepad-group:not([data-drop])'));

    expect(fetchMock).not.toHaveBeenCalled();
    expect(water.classList.contains('saving')).toBe(false);
  });
});

describe('crossing a job off', () => {
  const tick = (id) => document.querySelector(`.notepad-job[data-id="${id}"] .notepad-tick`);
  const keepers = (call) => fetchMock.mock.calls[call][1].body.getAll('keep[]');

  it('marks the row as saving until the server answers', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    submit(tick(1));

    expect(document.querySelector('.notepad-job[data-id="1"]').classList.contains('saving')).toBe(true);
  });

  it('tells the server to leave the job where it is', async () => {
    fetchMock.mockResolvedValue(answer());
    await start();
    submit(tick(1));

    expect(keepers(0)).toEqual(['1']);
  });

  it('goes on saying so in later requests, until the page is loaded again', async () => {
    fetchMock.mockImplementation(() => Promise.resolve(answer(`<div class="notepad-group">${row(1, 'Water')}${row(2, 'Weed')}</div>`)));
    await start();
    submit(tick(1));
    await flush();
    document.querySelector('.notepad-add input[type="text"]').value = 'Another';
    submit(document.querySelector('.notepad-add'));

    expect(keepers(1)).toEqual(['1']);
  });

  it('stops saying so for a job that is put back', async () => {
    fetchMock.mockImplementation(() => Promise.resolve(answer(`<div class="notepad-group">${row(1, 'Water')}</div>`)));
    await start();
    submit(tick(1));
    await flush();
    tick(1).querySelector('input[name="job[finished]"]').value = '0';
    submit(tick(1));

    expect(keepers(1)).toEqual([]);
  });

  it('shows how many jobs are done this week', async () => {
    fetchMock.mockResolvedValue(answer(`<div class="notepad-group">${row(1, 'Water')}</div>`, '3'));
    await start();
    submit(tick(1));
    await flush();

    expect(document.getElementById('notepad-snail-caption').textContent).toBe('Slow and steady. 3 jobs done this week.');
  });
});

describe('editing a job in place', () => {
  const water = () => document.querySelector('.notepad-job[data-id="1"]');
  const open = () => water().querySelector('[data-notepad-edit]').dispatchEvent(new MouseEvent('click', {bubbles: true, cancelable: true}));
  const box = () => water().querySelector('.notepad-name-input');
  const key = (name) => box().dispatchEvent(new KeyboardEvent('keydown', {key: name, bubbles: true, cancelable: true}));

  it('turns the row into an editor, with the name in a box', async () => {
    await start();
    open();

    expect(water().classList.contains('editing')).toBe(true);
    expect(box().value).toBe('Water');
    expect(box().getAttribute('aria-label')).toBe('Job name');
  });

  it('shows the hint and hides the plain name', async () => {
    await start();
    open();

    expect(water().querySelector('.notepad-edit-hint').hidden).toBe(false);
    expect(water().querySelector('.notepad-name').hidden).toBe(true);
  });

  it('does not follow the link to the form', async () => {
    await start();
    const click = new MouseEvent('click', {bubbles: true, cancelable: true});
    water().querySelector('[data-notepad-edit]').dispatchEvent(click);

    expect(click.defaultPrevented).toBe(true);
  });

  it('puts the row back on Escape, saving nothing', async () => {
    await start();
    open();
    box().value = 'Something else';
    key('Escape');

    expect(box()).toBeNull();
    expect(water().classList.contains('editing')).toBe(false);
    expect(water().querySelector('.notepad-name').textContent).toBe('Water');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('saves the new name on Enter', async () => {
    fetchMock.mockResolvedValue(answer());
    await start();
    open();
    box().value = 'Water the beans';
    key('Enter');

    const [url, options] = fetchMock.mock.calls[0];
    expect([url, options.body.get('_method'), options.body.get('job[name]')]).toEqual(['/jobs/water', 'patch', 'Water the beans']);
  });

  it('marks the row as saving while it is sent', async () => {
    fetchMock.mockReturnValue(new Promise(() => {}));
    await start();
    open();
    box().value = 'Water the beans';
    key('Enter');

    expect(water().classList.contains('saving')).toBe(true);
    expect(box().readOnly).toBe(true);
  });

  it('saves when you click away', async () => {
    fetchMock.mockResolvedValue(answer());
    await start();
    open();
    box().value = 'Water the beans';
    box().dispatchEvent(new Event('blur'));

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('saves nothing when the name is unchanged', async () => {
    await start();
    open();
    key('Enter');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(box()).toBeNull();
  });

  it('saves nothing when the name is emptied', async () => {
    await start();
    open();
    box().value = '   ';
    key('Enter');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(water().classList.contains('editing')).toBe(false);
  });

  it('keeps the box, with what was typed, when saving fails', async () => {
    fetchMock.mockResolvedValue({ok: false, status: 500, headers: {get: () => null}, text: () => Promise.resolve('')});
    await start();
    open();
    box().value = 'Water the beans';
    key('Enter');
    await flush();

    expect(box().value).toBe('Water the beans');
    expect(water().classList.contains('error')).toBe(true);
    expect(water().classList.contains('saving')).toBe(false);
  });
});
