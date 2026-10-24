import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import FeedMore from './FeedMore';

function stubReplies(...replies) {
  const fetch = vi.fn();
  replies.forEach((data) => fetch.mockResolvedValueOnce({ok: true, status: 200, json: async () => data}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

describe('FeedMore', () => {
  it('shows the button', () => {
    render(<FeedMore url="/feed?page=2" label="Show earlier days" />);
    expect(screen.getByRole('button', {name: 'Show earlier days'})).toBeInTheDocument();
  });

  it('fetches the chunk it was given', async () => {
    const fetch = stubReplies({html: '<p>Monday</p>', next: null});
    render(<FeedMore url="/feed?page=2" label="More" />);
    await userEvent.click(screen.getByRole('button'));
    expect(fetch).toHaveBeenCalledWith('/feed?page=2', expect.anything());
  });

  it('adds the chunk below', async () => {
    stubReplies({html: '<p>Monday</p>', next: null});
    render(<FeedMore url="/feed?page=2" label="More" />);
    await userEvent.click(screen.getByRole('button'));
    expect(await screen.findByText('Monday')).toBeInTheDocument();
  });

  it('fetches the next chunk the reply points to', async () => {
    const fetch = stubReplies({html: '<p>Monday</p>', next: '/feed?page=3'}, {html: '<p>Sunday</p>', next: null});
    render(<FeedMore url="/feed?page=2" label="More" />);
    await userEvent.click(screen.getByRole('button'));
    await screen.findByText('Monday');
    await userEvent.click(screen.getByRole('button'));
    expect(fetch).toHaveBeenLastCalledWith('/feed?page=3', expect.anything());
  });

  describe('when there is no more', () => {
    it('removes the button', async () => {
      stubReplies({html: '<p>Monday</p>', next: null});
      render(<FeedMore url="/feed?page=2" label="More" />);
      await userEvent.click(screen.getByRole('button'));
      await screen.findByText('Monday');
      expect(screen.queryByRole('button')).not.toBeInTheDocument();
    });
  });
});
