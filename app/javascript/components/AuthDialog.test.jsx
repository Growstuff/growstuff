import {fireEvent, render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it} from 'vitest';

import AuthDialog from './AuthDialog';

const urls = {sign_in: '/s', sign_up: '/u', forgot_password: '/f', sign_in_page: '/si', sign_up_page: '/su'};

function setup() {
  render(
      <>
        <a href="/members/sign_in" data-auth-dialog="sign_in">Log in</a>
        <a href="/members/sign_up" data-auth-dialog="sign_up">Join</a>
        <a href="/members/sign_in" data-auth-dialog="bluesky">Bluesky</a>
        <a href="/about">About</a>
        <AuthDialog urls={urls} site_name="Growstuff" />
      </>,
  );
}

describe('AuthDialog', () => {
  it('draws nothing to start with', () => {
    setup();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens sign in from a sign in link', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    expect(screen.getByRole('dialog', {name: 'Sign in'})).toBeInTheDocument();
  });

  it('opens sign up from a sign up link', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Join'}));
    expect(screen.getByRole('dialog', {name: 'Join Growstuff'})).toBeInTheDocument();
  });

  it('opens the Bluesky dialog from a Bluesky link', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Bluesky'}));
    expect(screen.getByRole('dialog', {name: 'Sign in with Bluesky'})).toBeInTheDocument();
  });

  it('ignores other links', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'About'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('leaves a ctrl-click to open in a new tab', () => {
    setup();
    fireEvent.click(screen.getByRole('link', {name: 'Log in'}), {ctrlKey: true});
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('switches from sign in to sign up', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    await userEvent.click(screen.getByRole('link', {name: 'Join free'}));
    expect(screen.getByRole('dialog', {name: 'Join Growstuff'})).toBeInTheDocument();
  });

  it('closes', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    await userEvent.click(screen.getByRole('button', {name: 'Close'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
