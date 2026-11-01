import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it} from 'vitest';

import MastodonModal from './MastodonModal';

describe('MastodonModal', () => {
  const show = () => render(<MastodonModal urls={{mastodon: '/members/auth/mastodon'}} onClose={() => {}} />);

  it('posts to the Mastodon authorization endpoint', () => {
    show();
    expect(screen.getByLabelText('Mastodon address').closest('form')).toHaveAttribute('action', '/members/auth/mastodon');
  });

  it('uses the identifier expected by the provider', () => {
    show();
    expect(screen.getByLabelText('Mastodon address')).toHaveAttribute('name', 'identifier');
  });

  it('requires agreement to the terms', () => {
    show();
    expect(screen.getByRole('checkbox', {name: /Terms of Service/})).toBeRequired();
  });

  it('disables submission while contacting the server', async () => {
    show();
    screen.getByLabelText('Mastodon address').closest('form').addEventListener('submit', (event) => event.preventDefault());
    await userEvent.type(screen.getByLabelText('Mastodon address'), 'alice@mastodon.social');
    await userEvent.click(screen.getByRole('checkbox', {name: /Terms of Service/}));
    await userEvent.click(screen.getByRole('button', {name: 'Continue with Mastodon'}));
    expect(screen.getByRole('button', {name: /Contacting Mastodon/})).toBeDisabled();
  });
});
