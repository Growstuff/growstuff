import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';

// How the notepad sends changes: one at a time, in order, and keeping the
// keyboard's place in the list when it is drawn again.

const CELEBRATIONS = {
  levels: {
    one: {lead: 'Nice one!', note: 'x'}, two: {lead: 'Two!', note: 'x'}, three: {lead: 'Three!', note: 'x'}, many: {lead: 'Many!', note: 'x'},
  },
  slow: 'Slow and steady.',
  crossed_off: 'Crossed off "%{name}"',
  undo: 'Undo',
  done: {one: '1 job done this week.', other: '%{count} jobs done this week.'},
};

const row = (id, name) => `
  <div class="notepad-job" data-url="/jobs/${name.toLowerCase()}" data-id="${id}">
    <form class="notepad-tick" action="/jobs/${name.toLowerCase()}" method="post">
      <input type="hidden" name="_method" value="patch">
      <input type="hidden" name="job[finished]" value="1">
      <button type="submit" class="notepad-box"></button>
    </form>
    <span class="notepad-name">${name}</span>
    <div class="notepad-menu"><button type="button" class="record-actions-toggle">...</button></div>
  </div>`;

const list = `<div class="notepad-group">${row(1, 'Water')}${row(2, 'Weed')}</div>`;

const page = () => `
  <meta name="csrf-token" content="token-123">
  <form class="notepad-add" action="/jobs" method="post" data-kinds='{}'>
    <input type="text" name="job[name]">
    <input type="submit" value="Add">
    <input type="hidden" id="notepad-jobbable-type"><input type="hidden" id="notepad-jobbable-id">
    <ul id="notepad-suggestions" hidden></ul>
  </form>
  <div id="notepad-link" hidden><span class="notepad-link-text"></span><button type="button">x</button></div>
  <p id="notepad-add-failed" hidden>failed</p>
  <div id="notepad-groups" data-celebrations='${JSON.stringify(CELEBRATIONS)}'>${list}</div>
  <span id="notepad-snail-caption">Slow and steady.</span>`;

const answer = (html = list, done = '0') => ({ok: true, headers: {get: () => done}, text: () => Promise.resolve(html)});
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const tick = (id) => document.querySelector(`.notepad-job[data-id="${id}"] .notepad-tick`);
const box = (id) => tick(id).querySelector('.notepad-box');
const submit = (form) => form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true}));

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

let fetchMock;

beforeEach(() => {
  document.body.innerHTML = page();
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
});

afterEach(() => {
  document.body.innerHTML = '';
});

describe('sending changes', () => {
  it('sends one at a time, the next only once the one before has landed', async () => {
    let finishFirst;
    fetchMock.mockReturnValueOnce(new Promise((resolve) => { finishFirst = resolve; })).mockResolvedValue(answer());
    await start();
    submit(tick(1));
    submit(tick(2));
    await flush();

    expect(fetchMock).toHaveBeenCalledTimes(1);

    finishFirst(answer());
    await flush();

    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('sends them in the order they were made', async () => {
    fetchMock.mockResolvedValue(answer());
    await start();
    submit(tick(2));
    submit(tick(1));
    await flush();
    await flush();

    expect(fetchMock.mock.calls.map(([url]) => url.split('/').pop())).toEqual(['weed', 'water']);
  });

  it('does not let an older answer, arriving last, replace a newer list', async () => {
    let finishFirst;
    fetchMock
      .mockReturnValueOnce(new Promise((resolve) => { finishFirst = resolve; }))
      .mockResolvedValueOnce(answer('<div class="notepad-group" id="newer"></div>', '2'));
    await start();
    submit(tick(1));
    submit(tick(2));
    await flush();
    finishFirst(answer('<div class="notepad-group" id="older"></div>', '1'));
    await flush();
    await flush();

    expect(document.querySelector('#notepad-groups #newer')).not.toBeNull();
    expect(document.querySelector('#notepad-groups #older')).toBeNull();
    expect(document.getElementById('notepad-snail-caption').textContent).toBe('Slow and steady. 2 jobs done this week.');
  });

  it('goes on with the next change when one fails', async () => {
    fetchMock
      .mockResolvedValueOnce({ok: false, status: 500, headers: {get: () => null}, text: () => Promise.resolve('')})
      .mockResolvedValue(answer());
    await start();
    submit(tick(1));
    submit(tick(2));
    await flush();
    await flush();

    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});

describe('after the list is drawn again', () => {
  it('puts focus back on the tick box that had it', async () => {
    fetchMock.mockResolvedValue(answer());
    await start();
    box(1).focus();
    submit(tick(1));
    await flush();

    expect(document.activeElement).toBe(box(1));
  });

  it('puts focus back on a menu button that had it', async () => {
    fetchMock.mockResolvedValue(answer());
    await start();
    document.querySelector('.notepad-job[data-id="2"] .record-actions-toggle').focus();
    submit(tick(1));
    await flush();

    expect(document.activeElement).toBe(document.querySelector('.notepad-job[data-id="2"] .record-actions-toggle'));
  });

  it('does not take focus back from where it has moved to', async () => {
    fetchMock.mockResolvedValue(answer());
    await start();
    box(1).focus();
    submit(tick(1));
    document.querySelector('.notepad-add input[type="text"]').focus();
    await flush();

    expect(document.activeElement).toBe(document.querySelector('.notepad-add input[type="text"]'));
  });

  it('leaves focus alone when the job is no longer in the list', async () => {
    fetchMock.mockResolvedValue(answer(`<div class="notepad-group">${row(2, 'Weed')}</div>`));
    await start();
    box(1).focus();
    submit(tick(1));
    await flush();

    expect(document.activeElement).not.toBe(box(2));
  });
});
