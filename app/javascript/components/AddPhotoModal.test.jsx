import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {beforeEach, describe, expect, it, vi} from 'vitest';

import AddPhotoModal from './AddPhotoModal';

const photo = {id: '1234', title: 'Net on', thumb_url: '/t.jpg', preview_url: '/p.jpg'};
const ready = {state: 'ready', photos: [photo], sets: [], page: 1, total_pages: 1, name: 'Sam', profile_url: 'https://example.com/sam'};

// Answers the photo list, and anything else (the add) with a created photo.
function stubFetch() {
  const fetch = vi.fn(async (url) => ({ok: true, status: url.startsWith('/photos/new') ? 200 : 201, json: async () => (url.startsWith('/photos/new') ? ready : {})}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

async function addPhoto(newUrl) {
  const user = userEvent.setup();
  render(<AddPhotoModal label="Net the berries" newUrl={newUrl} onClose={vi.fn()} onAdded={vi.fn()} />);
  await user.click(await screen.findByRole('button', {name: 'Net on'}));
  await user.click(screen.getByRole('button', {name: 'Add photo'}));
}

describe('AddPhotoModal', () => {
  let fetch;

  beforeEach(() => {
    fetch = stubFetch();
  });

  it('adds the photo to the thing the link is for', async () => {
    await addPhoto('/photos/new?type=planting&id=5');
    expect(fetch).toHaveBeenLastCalledWith('/photos.json?type=planting&id=5', expect.anything());
  });

  it('says when a job\'s photo was taken', async () => {
    await addPhoto('/photos/new?type=job&id=5&label=before');
    expect(fetch).toHaveBeenLastCalledWith('/photos.json?type=job&id=5&label=before', expect.anything());
  });
});
