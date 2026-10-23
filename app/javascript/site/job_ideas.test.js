import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';
import {addedBlock} from './job_ideas';

// The ideas overlay: opened from the links, choosing an idea without leaving the
// page, and showing the jobs an idea made.

const idea = (key, name) => `
  <div class="idea" data-key="${key}">
    <div class="idea-title">${name}</div>
    <form class="idea-form button_to" action="/job_ideas" method="post">
      <input type="hidden" name="key" value="${key}"><button type="submit">Add</button>
    </form>
  </div>`;

const page = () => `
  <meta name="csrf-token" content="token-123">
  <a href="/job_ideas" data-job-ideas-open>Ideas</a>
  <span data-ideas-badge>2</span>
  <a class="notepad-ideas" href="/job_ideas"><span class="notepad-ideas-text">We have 2</span></a>
  <div id="notepad-groups"><div class="notepad-job" data-id="1">Water</div></div>
  <div class="modal" id="job-ideas-modal" data-url="/job_ideas"><div id="job-ideas-body"></div></div>`;

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const json = (data) => ({ok: true, json: () => Promise.resolve(data)});
const html = (text) => ({ok: true, text: () => Promise.resolve(text)});
const body = () => document.getElementById('job-ideas-body');
const submit = (form) => form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true}));

// The script wires itself up when the page has loaded. Import it fresh for each
// test and run that step by hand.
const start = async () => {
  vi.resetModules();
  const listen = vi.spyOn(document, 'addEventListener').mockImplementation(() => {});
  await import('./job_ideas');
  const handlers = listen.mock.calls.filter(([name]) => name === 'DOMContentLoaded').map(([, handler]) => handler);
  listen.mockRestore();
  handlers.forEach((handler) => handler());
};

let fetchMock;
let show;

beforeEach(() => {
  document.body.innerHTML = page();
  fetchMock = vi.fn();
  show = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
  // Asking for less motion makes every pause end at once.
  vi.stubGlobal('matchMedia', () => ({matches: true}));
  window.bootstrap = {Modal: {getOrCreateInstance: () => ({show})}};
});

afterEach(() => {
  document.body.innerHTML = '';
  delete window.bootstrap;
});

describe('addedBlock', () => {
  const data = {added_label: 'Added 2 jobs', added: [{id: 1, name: 'Stake', due: '5 Nov'}, {id: 2, name: 'Feed', due: null}]};

  it('says what was added', () => {
    expect(addedBlock(data).querySelector('.idea-added-label').textContent).toBe('✓ Added 2 jobs');
  });

  it('lists each job with its day', () => {
    expect(Array.from(addedBlock(data).querySelectorAll('li')).map((li) => li.textContent)).toEqual(['5 Nov Stake', 'Feed']);
  });

  it('brings each job in a moment after the one before', () => {
    expect(Array.from(addedBlock(data).querySelectorAll('li')).map((li) => li.style.animationDelay)).toEqual(['0ms', '90ms']);
  });
});

describe('opening', () => {
  it('loads the ideas into the overlay', async () => {
    fetchMock.mockResolvedValue(html(idea('a', 'Snip')));
    await start();
    document.querySelector('[data-job-ideas-open]').click();
    await flush();
    expect(body().querySelectorAll('.idea').length).toBe(1);
  });

  it('shows the overlay', async () => {
    fetchMock.mockResolvedValue(html(idea('a', 'Snip')));
    await start();
    document.querySelector('[data-job-ideas-open]').click();
    await flush();
    expect(show).toHaveBeenCalled();
  });
});

describe('choosing an idea', () => {
  const added = {
    added: [{id: 7, name: 'Plant tomato', due: null}], added_label: 'Added 1 job to your list', count: 1, banner: 'We have 1',
    groups: '<div class="notepad-job" data-id="1">Water</div><div class="notepad-job" data-id="7">Plant tomato</div>',
    list: idea('b', 'Dig'),
  };

  const choose = async () => {
    fetchMock.mockResolvedValueOnce(html(idea('a', 'Snip') + idea('b', 'Dig'))).mockResolvedValueOnce(json(added));
    await start();
    document.querySelector('[data-job-ideas-open]').click();
    await flush();
    submit(body().querySelector('.idea-form'));
    await flush();
    await flush();
  };

  it('sends it in the background', async () => {
    await choose();
    expect(new URL(fetchMock.mock.calls[1][0]).pathname).toBe('/job_ideas');
  });

  it('sends the token', async () => {
    await choose();
    expect(fetchMock.mock.calls[1][1].headers['X-CSRF-Token']).toBe('token-123');
  });

  it('marks the new job in the notepad', async () => {
    await choose();
    expect(document.querySelector('.notepad-job[data-id="7"]').classList.contains('just-added')).toBe(true);
  });

  it('does not mark the jobs that were there', async () => {
    await choose();
    expect(document.querySelector('.notepad-job[data-id="1"]').classList.contains('just-added')).toBe(false);
  });

  it('puts the ideas that are left in the overlay', async () => {
    await choose();
    expect(Array.from(body().querySelectorAll('.idea')).map((el) => el.dataset.key)).toEqual(['b']);
  });

  it('updates the count on the link', async () => {
    await choose();
    expect(document.querySelector('[data-ideas-badge]').textContent).toBe('1');
  });

  it('updates the words in the box', async () => {
    await choose();
    expect(document.querySelector('.notepad-ideas-text').textContent).toBe('We have 1');
  });

  it('hides the box when there are no ideas left', async () => {
    fetchMock.mockResolvedValueOnce(html(idea('a', 'Snip'))).mockResolvedValueOnce(json({...added, count: 0, list: ''}));
    await start();
    document.querySelector('[data-job-ideas-open]').click();
    await flush();
    submit(body().querySelector('.idea-form'));
    await flush();
    await flush();
    expect(document.querySelector('.notepad-ideas').hidden).toBe(true);
  });

  it('sends the choice the ordinary way if it could not be sent', async () => {
    fetchMock.mockResolvedValueOnce(html(idea('a', 'Snip'))).mockRejectedValueOnce(new Error('offline'));
    await start();
    document.querySelector('[data-job-ideas-open]').click();
    await flush();
    const form = body().querySelector('.idea-form');
    form.submit = vi.fn();
    submit(form);
    await flush();
    expect(form.submit).toHaveBeenCalled();
  });
});
