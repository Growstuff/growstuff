import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it} from 'vitest';

import BlueskyModal from './BlueskyModal';

describe('BlueskyModal', () => {
  it('posts the handle to the server', () => {
    render(<BlueskyModal urls={{bluesky: '/members/auth/bluesky'}} onClose={() => {}} />);
    expect(screen.getByLabelText('Bluesky handle').closest('form')).toHaveAttribute('action', '/members/auth/bluesky');
  });

  it('says it is working once the handle is sent', async () => {
    render(<BlueskyModal urls={{bluesky: '/members/auth/bluesky'}} onClose={() => {}} />);
    screen.getByLabelText('Bluesky handle').closest('form').addEventListener('submit', (event) => event.preventDefault());
    await userEvent.type(screen.getByLabelText('Bluesky handle'), 'alice');
    await userEvent.click(screen.getByRole('checkbox', {name: /Terms of Service/}));
    await userEvent.click(screen.getByRole('button', {name: 'Continue with Bluesky'}));
    expect(screen.getByRole('button', {name: /Contacting Bluesky/})).toBeDisabled();
  });

  it('asks for the terms of service before going to Bluesky', () => {
    render(<BlueskyModal urls={{bluesky: '/members/auth/bluesky'}} onClose={() => {}} />);
    expect(screen.getByRole('checkbox', {name: /Terms of Service/})).toBeRequired();
  });
});
