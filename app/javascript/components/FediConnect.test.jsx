import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it} from 'vitest';

import FediConnect from './FediConnect';

describe('FediConnect', () => {
  const copy = {title: 'Add a Fedi account', label: 'Server address', placeholder: 'example.social', hint: 'Just the server.',
    submit: 'Connect', busy: 'Connecting…'};
  const show = () => render(<FediConnect url="/members/auth/mastodon" buttonLabel="Add Fedi" copy={copy} />);

  it('starts with just the button', () => {
    show();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens a dialog asking for the server address', async () => {
    show();
    await userEvent.click(screen.getByRole('button', {name: 'Add Fedi'}));
    expect(screen.getByLabelText('Server address')).toBeInTheDocument();
  });

  it('posts the address to the connect endpoint', async () => {
    show();
    await userEvent.click(screen.getByRole('button', {name: 'Add Fedi'}));
    expect(screen.getByLabelText('Server address').closest('form')).toHaveAttribute('action', '/members/auth/mastodon');
  });

  it('does not ask for the terms of service', async () => {
    show();
    await userEvent.click(screen.getByRole('button', {name: 'Add Fedi'}));
    expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
  });
});
