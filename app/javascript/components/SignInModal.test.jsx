import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import SignInModal from './SignInModal';

const urls = {sign_in: '/members/sign_in', forgot_password: '/members/password/new', sign_up_page: '/members/sign_up'};

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

async function signIn() {
  await userEvent.type(screen.getByLabelText('Login name or email'), 'sam');
  await userEvent.type(screen.getByLabelText('Password'), 'secret');
  await userEvent.click(screen.getByRole('button', {name: 'Sign in'}));
}

function setup(props = {}) {
  render(<SignInModal urls={urls} onClose={vi.fn()} onSwitch={vi.fn()} {...props} />);
}

describe('SignInModal', () => {
  it('links to the forgotten password page', () => {
    stubFetch({ok: true, status: 200});
    setup();
    expect(screen.getByRole('link', {name: 'Forgot password?'})).toHaveAttribute('href', urls.forgot_password);
  });

  it('keeps me signed in by default', () => {
    stubFetch({ok: true, status: 200});
    setup();
    expect(screen.getByLabelText('Keep me signed in')).toBeChecked();
  });

  it('switches to joining', async () => {
    const onSwitch = vi.fn();
    stubFetch({ok: true, status: 200});
    setup({onSwitch});
    await userEvent.click(screen.getByRole('link', {name: 'Join free'}));
    expect(onSwitch).toHaveBeenCalledTimes(1);
  });

  it('posts the login to Devise', async () => {
    const fetch = stubFetch({ok: true, status: 200});
    setup();
    await signIn();
    expect(fetch).toHaveBeenCalledWith(urls.sign_in, expect.objectContaining({
      body: JSON.stringify({member: {login: 'sam', password: 'secret', remember_me: '1'}}),
    }));
  });

  describe('when the login is wrong', () => {
    it('shows the server\'s message', async () => {
      stubFetch({ok: false, status: 401, data: {error: 'Invalid login or password.'}});
      setup();
      await signIn();
      expect(await screen.findByRole('alert')).toHaveTextContent('Invalid login or password.');
    });

    it('stays open for another go', async () => {
      stubFetch({ok: false, status: 401, data: {error: 'Invalid login or password.'}});
      setup();
      await signIn();
      await screen.findByRole('alert');
      expect(screen.getByRole('button', {name: 'Sign in'})).toBeEnabled();
    });
  });

  describe('when something else goes wrong', () => {
    it('apologises', async () => {
      stubFetch({ok: false, status: 500});
      setup();
      await signIn();
      expect(await screen.findByRole('alert')).toHaveTextContent('Something went wrong signing in');
    });
  });

  describe('when the request fails', () => {
    it('apologises', async () => {
      vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
      setup();
      await signIn();
      expect(await screen.findByRole('alert')).toHaveTextContent('Something went wrong signing in');
    });
  });
});
