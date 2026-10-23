import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import SignUpModal from './SignUpModal';

const urls = {sign_up: '/members', sign_in_page: '/members/sign_in'};

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  render(<SignUpModal urls={urls} siteName="Growstuff" onClose={vi.fn()} onSwitch={vi.fn()} {...props} />);
}

async function signUp() {
  await userEvent.type(screen.getByLabelText('Login name'), 'sam');
  await userEvent.type(screen.getByLabelText('Email'), 'sam@example.com');
  await userEvent.type(screen.getByLabelText('Password', {selector: '#sign-up-password'}), 'secret');
  await userEvent.click(screen.getByLabelText(/Terms of Service/));
  await userEvent.click(screen.getByRole('button', {name: 'Sign up'}));
}

describe('SignUpModal', () => {
  it('is titled with the site name', () => {
    setup();
    expect(screen.getByRole('dialog', {name: 'Join Growstuff'})).toBeInTheDocument();
  });

  it('offers the newsletter, ticked', () => {
    setup();
    expect(screen.getByLabelText('Subscribe to the Growstuff newsletter')).toBeChecked();
  });

  it('does not tick the terms for me', () => {
    setup();
    expect(screen.getByLabelText(/Terms of Service/)).not.toBeChecked();
  });

  it('switches to signing in', async () => {
    const onSwitch = vi.fn();
    setup({onSwitch});
    await userEvent.click(screen.getByRole('link', {name: 'Sign in'}));
    expect(onSwitch).toHaveBeenCalledTimes(1);
  });

  it('has no captcha note without a site key', () => {
    setup();
    expect(screen.queryByText(/accessibility issues with the captcha/)).not.toBeInTheDocument();
  });

  it('has a captcha note with a site key', () => {
    setup({recaptchaSiteKey: 'key'});
    expect(screen.getByText(/accessibility issues with the captcha/)).toBeInTheDocument();
  });

  it('posts the member to Devise', async () => {
    const fetch = stubFetch({ok: true, status: 201, data: {}});
    setup();
    await signUp();
    expect(JSON.parse(fetch.mock.calls[0][1].body).member).toMatchObject({login_name: 'sam', email: 'sam@example.com', tos_agreement: true});
  });

  describe('when the server rejects a field', () => {
    it('shows the error against the field', async () => {
      stubFetch({ok: false, status: 422, data: {errors: {email: ['is invalid']}}});
      setup();
      await signUp();
      expect(await screen.findByLabelText('Email')).toHaveAccessibleDescription(/is invalid/);
    });
  });

  describe('when the server rejects something that is not a field', () => {
    it('shows it above the form', async () => {
      stubFetch({ok: false, status: 422, data: {errors: {base: ['Captcha failed']}}});
      setup();
      await signUp();
      expect(await screen.findByRole('alert')).toHaveTextContent('Captcha failed');
    });
  });

  describe('when the request fails', () => {
    it('apologises', async () => {
      vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
      setup();
      await signUp();
      expect(await screen.findByRole('alert')).toHaveTextContent('Something went wrong joining');
    });
  });
});
