import {fireEvent, render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';

import AuthDialog from './AuthDialog';

const urls = {sign_in: '/s', sign_up: '/u', forgot_password: '/f', sign_in_page: '/si', sign_up_page: '/su', bluesky: '/b', mastodon: '/m', github: '/g'};
const githubLabels = {continue: 'Continue with GitHub'};

function setup(pageUrls = urls) {
  render(
      <>
        <a href="/members/sign_in" data-auth-dialog="sign_in">Log in</a>
        <a href="/members/sign_up" data-auth-dialog="sign_up">Join</a>
        <a href="/members/sign_in" data-auth-dialog="bluesky">Bluesky</a>
        <a href="/members/sign_in" data-auth-dialog="mastodon">Mastodon</a>
        <a href="/members/sign_in" data-auth-dialog="github">GitHub</a>
        <a href="/about">About</a>
        <AuthDialog urls={pageUrls} site_name="Growstuff" github_labels={githubLabels} />
      </>,
  );
}

describe('AuthDialog', () => {
  let githubSubmit;
  beforeEach(() => {
    githubSubmit = vi.spyOn(HTMLFormElement.prototype, 'submit').mockImplementation(() => {});
  });
  afterEach(() => vi.restoreAllMocks());

  describe.each(['Bluesky', 'Mastodon'])('%s terms agreement', (provider) => {
    it('does not prompt when signing in from a provider link', async () => {
      setup();
      await userEvent.click(screen.getByRole('link', {name: provider}));
      expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
    });

    it('does not prompt when continuing from sign in', async () => {
      setup();
      await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
      await userEvent.click(screen.getByRole('button', {name: `Continue with ${provider}`}));
      expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
    });

    it('requires agreement when continuing from sign up', async () => {
      setup();
      await userEvent.click(screen.getByRole('link', {name: 'Join'}));
      await userEvent.click(screen.getByRole('button', {name: `Continue with ${provider}`}));
      expect(screen.getByRole('checkbox')).toBeRequired();
    });
  });

  it('draws nothing to start with', () => {
    setup();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('posts the GitHub form to its authorization endpoint', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'GitHub'}));
    expect(githubSubmit.mock.instances[0]).toHaveAttribute('action', urls.github);
  });

  it('uses POST for GitHub authorization', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'GitHub'}));
    expect(githubSubmit.mock.instances[0]).toHaveAttribute('method', 'post');
  });

  it('sends the CSRF token with GitHub authorization', async () => {
    const meta = document.createElement('meta');
    meta.name = 'csrf-token';
    meta.content = 'csrf-token';
    document.head.appendChild(meta);
    try {
      setup();
      await userEvent.click(screen.getByRole('link', {name: 'GitHub'}));
      expect(githubSubmit.mock.instances[0].elements.authenticity_token.value).toBe('csrf-token');
    } finally {
      meta.remove();
    }
  });

  it('hides GitHub when it is switched off', async () => {
    setup({...urls, github: null});
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    expect(screen.queryByRole('button', {name: githubLabels.continue})).not.toBeInTheDocument();
  });

  it('starts GitHub authorization without an interim dialog', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'GitHub'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('starts GitHub authorization directly from sign in', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    await userEvent.click(screen.getByRole('button', {name: githubLabels.continue}));
    expect(githubSubmit).toHaveBeenCalledOnce();
  });

  it('does not assume terms acceptance when signing in', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    await userEvent.click(screen.getByRole('button', {name: githubLabels.continue}));
    expect(githubSubmit.mock.instances[0].elements.tos_agreement).toBeUndefined();
  });

  it('passes accepted signup terms to GitHub authorization', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Join'}));
    await userEvent.click(screen.getByRole('checkbox'));
    await userEvent.click(screen.getByRole('button', {name: githubLabels.continue}));
    expect(githubSubmit.mock.instances[0].elements.tos_agreement.value).toBe('1');
  });

  it('leaves unaccepted signup terms for signup completion', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Join'}));
    await userEvent.click(screen.getByRole('button', {name: githubLabels.continue}));
    expect(githubSubmit.mock.instances[0].elements.tos_agreement).toBeUndefined();
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

  it('moves from the sign in dialog to Bluesky', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    await userEvent.click(screen.getByRole('button', {name: 'Continue with Bluesky'}));
    expect(screen.getByRole('dialog', {name: 'Sign in with Bluesky'})).toBeInTheDocument();
  });

  it('moves from the sign up dialog to Bluesky', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Join'}));
    await userEvent.click(screen.getByRole('button', {name: 'Continue with Bluesky'}));
    expect(screen.getByRole('dialog', {name: 'Sign in with Bluesky'})).toBeInTheDocument();
  });

  it('offers no Bluesky button when it is switched off', async () => {
    setup({...urls, bluesky: null});
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    expect(screen.queryByRole('button', {name: 'Continue with Bluesky'})).not.toBeInTheDocument();
  });

  it('ignores other links', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'About'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens Mastodon from a Mastodon link', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Mastodon'}));
    expect(screen.getByRole('dialog', {name: 'Sign in with Mastodon'})).toBeInTheDocument();
  });

  it('moves from sign in to Mastodon', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    await userEvent.click(screen.getByRole('button', {name: 'Continue with Mastodon'}));
    expect(screen.getByRole('dialog', {name: 'Sign in with Mastodon'})).toBeInTheDocument();
  });

  it('moves from sign up to Mastodon', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Join'}));
    await userEvent.click(screen.getByRole('button', {name: 'Continue with Mastodon'}));
    expect(screen.getByRole('dialog', {name: 'Sign in with Mastodon'})).toBeInTheDocument();
  });

  it('hides Mastodon when it is switched off', async () => {
    setup({...urls, mastodon: null});
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));
    expect(screen.queryByRole('button', {name: 'Continue with Mastodon'})).not.toBeInTheDocument();
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

  it('closes an open offcanvas when an auth link is clicked', async () => {
    const hide = vi.fn();
    window.bootstrap = {
      Offcanvas: {
        getInstance: vi.fn(() => ({hide})),
        getOrCreateInstance: vi.fn(() => ({hide})),
      },
    };

    const offcanvas = document.createElement('div');
    offcanvas.id = 'navbarSupportedContent';
    offcanvas.className = 'offcanvas-lg offcanvas-end show';
    document.body.appendChild(offcanvas);

    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Log in'}));

    expect(hide).toHaveBeenCalled();
    offcanvas.remove();
    delete window.bootstrap;
  });
});
