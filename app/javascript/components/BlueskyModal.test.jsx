import {render, screen} from '@testing-library/react';
import {describe, expect, it} from 'vitest';

import BlueskyModal from './BlueskyModal';

describe('BlueskyModal', () => {
  it('posts the handle to the server', () => {
    render(<BlueskyModal urls={{bluesky: '/members/auth/bluesky'}} onClose={() => {}} />);
    expect(screen.getByLabelText('Bluesky handle').closest('form')).toHaveAttribute('action', '/members/auth/bluesky');
  });
});
