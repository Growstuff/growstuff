import {render, screen, within} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import EmailStep from './EmailStep';

const urls = {update: '/my/email', decline: '/my/email/decline'};
const labels = {title: 'Add your email address', note: 'Without one…', declined: 'You chose not to add one.', changed_mind: 'Changed your mind?', save: 'Save email', add: 'Add email', decline: 'No thanks', skipped: 'Skipped', error: 'Try again'};

function stubFetch(ok = true) {
  const fetch = vi.fn(async () => ({ok, status: ok ? 204 : 500, json: async () => ({})}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  render(<EmailStep number={2} declined={false} urls={urls} labels={labels} {...props} />);
}

describe('EmailStep', () => {
  it('offers to add an email at first, without the form', () => {
    setup();
    expect(screen.queryByLabelText('Add your email address')).toBeNull();
  });

  it('opens a dialog for the email', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Add email'}));
    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });

  it('asks for the address in the dialog', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Add email'}));
    expect(within(screen.getByRole('dialog')).getByRole('textbox')).toHaveAttribute('type', 'email');
  });

  it('declines in place, without leaving the page', async () => {
    const fetch = stubFetch();
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'No thanks'}));
    expect(fetch).toHaveBeenCalledWith('/my/email/decline', expect.objectContaining({method: 'POST'}));
  });

  it('shows the row as skipped once declined', async () => {
    stubFetch();
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'No thanks'}));
    expect(await screen.findByLabelText('Skipped')).toBeInTheDocument();
  });

  it('hides the form once declined', async () => {
    stubFetch();
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'No thanks'}));
    await screen.findByLabelText('Skipped');
    expect(screen.queryByRole('button', {name: 'Add email'})).toBeNull();
  });

  it('keeps asking when declining fails', async () => {
    stubFetch(false);
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'No thanks'}));
    expect(await screen.findByText('Try again')).toBeInTheDocument();
  });

  it('opens the dialog again when they change their mind', async () => {
    setup({declined: true});
    await userEvent.click(screen.getByRole('button', {name: 'Changed your mind?'}));
    expect(screen.getByRole('button', {name: 'Save email'})).toBeInTheDocument();
  });

  it('offers No thanks again in the dialog', async () => {
    setup({declined: true});
    await userEvent.click(screen.getByRole('button', {name: 'Changed your mind?'}));
    expect(screen.getByRole('button', {name: 'No thanks'})).toBeInTheDocument();
  });

  it('closes the dialog on saying no thanks', async () => {
    stubFetch();
    setup({declined: true});
    await userEvent.click(screen.getByRole('button', {name: 'Changed your mind?'}));
    await userEvent.click(screen.getByRole('button', {name: 'No thanks'}));
    expect(await screen.findByLabelText('Skipped')).toBeInTheDocument();
  });
});
