import {afterEach, beforeAll, beforeEach, describe, expect, it, vi} from 'vitest';

// Ticking a job on a planting's page sends it and draws that one line again.

const item = (done) => `
  <li class="job-checklist-item${done ? ' done' : ''}" id="job_1">
    <form class="job-checklist-tick" action="/jobs/water" method="post">
      <input type="hidden" name="_method" value="patch">
      <input type="hidden" name="job[finished]" value="${done ? 0 : 1}">
      <button type="submit" class="job-box${done ? ' checked' : ''}"></button>
    </form>
  </li>`;

const tick = () => {
  const form = document.querySelector('.job-checklist-tick');
  form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true}));
};

describe('job checklist', () => {
  beforeAll(async () => {
    await import('./job_checklist');
  });

  beforeEach(() => {
    document.body.innerHTML = `<meta name="csrf-token" content="token-123"><ul>${item(false)}</ul>`;
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('draws the line again from what the server sends', async () => {
    const fetchMock = vi.fn(() => Promise.resolve({ok: true, text: () => Promise.resolve(item(true))}));
    vi.stubGlobal('fetch', fetchMock);
    tick();
    await vi.waitFor(() => expect(document.querySelector('.job-checklist-item.done')).not.toBeNull());
  });

  it('sends the tick with the page token', () => {
    const fetchMock = vi.fn(() => new Promise(() => {}));
    vi.stubGlobal('fetch', fetchMock);
    tick();
    expect(fetchMock.mock.calls[0][1].headers['X-CSRF-Token']).toBe('token-123');
  });
});
