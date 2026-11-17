import {render, screen, waitFor} from '@testing-library/react';
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

  describe('Mastodon', () => {
    const labels = {source: 'Photo source', flickr: 'Flickr', mastodon: 'Mastodon', account: 'Account',
      license_consent: 'Licence consent', license_hint: 'Licence explanation', more: 'More', recent: 'Recent', search: 'Search',
      add: 'Add photo', back: 'Back'};
    const accounts = [{id: 7, name: '@alice@example.social'}, {id: 8, name: '@alice@other.social'}];
    const mastodonPhoto = {...photo, status_id: '99', license_name: null};
    let mastodonData;

    beforeEach(() => {
      mastodonData = {state: 'ready', source: 'mastodon', photos: [mastodonPhoto], sets: [], authentication_id: 7,
        accounts, labels, next_cursor: '88', sources: ['flickr', 'mastodon']};
      fetch.mockImplementation(async (url) => ({ok: true, status: url.startsWith('/photos/new') ? 200 : 201,
        json: async () => url.startsWith('/photos/new') ? (url.includes('source=mastodon') ? mastodonData : {...ready, source: 'flickr', sources: ['flickr', 'mastodon'], labels, accounts}) : {}}));
    });

    function open(onAdded = vi.fn()) {
      render(<AddPhotoModal label="Tomatoes" newUrl="/photos/new?type=job&id=5&source=mastodon" onClose={vi.fn()} onAdded={onAdded} />);
    }

    async function choose() {
      const user = userEvent.setup();
      open();
      await user.click(await screen.findByRole('button', {name: photo.title}));
      return user;
    }

    it('starts with licence consent unchecked', async () => {
      await choose();
      expect(screen.getByRole('checkbox')).not.toBeChecked();
    });

    it('requires consent before adding an unlicensed image', async () => {
      await choose();
      expect(screen.getByRole('button', {name: 'Add photo'})).toBeDisabled();
    });

    it('sends explicit consent and the selected post identity', async () => {
      const user = await choose();
      await user.click(screen.getByRole('checkbox'));
      await user.click(screen.getByRole('button', {name: 'Add photo'}));
      expect(JSON.parse(fetch.mock.lastCall[1].body)).toEqual({authentication_id: 7,
        photo: {source: 'mastodon', source_id: photo.id, status_id: '99', license_accepted: true}});
    });

    it('resets consent when choosing another image', async () => {
      const user = await choose();
      await user.click(screen.getByRole('checkbox'));
      await user.click(screen.getByRole('button', {name: 'Back'}));
      await user.click(screen.getByRole('button', {name: photo.title}));
      expect(screen.getByRole('checkbox')).not.toBeChecked();
    });

    it('does not ask to relicense an image with a stated licence', async () => {
      mastodonData.photos = [{...mastodonPhoto, license_name: 'CC BY 4.0'}];
      await choose();
      expect(screen.queryByRole('checkbox')).not.toBeInTheDocument();
    });

    it('allows an image with a stated licence without new consent', async () => {
      mastodonData.photos = [{...mastodonPhoto, license_name: 'CC BY 4.0'}];
      await choose();
      expect(screen.getByRole('button', {name: 'Add photo'})).toBeEnabled();
    });

    it('uses cursor pagination', async () => {
      const user = userEvent.setup();
      open();
      await user.click(await screen.findByRole('button', {name: labels.more}));
      await waitFor(() => expect(fetch.mock.lastCall[0]).toContain('cursor=88'));
    });

    it('requests the selected linked account', async () => {
      const user = userEvent.setup();
      open();
      await user.selectOptions(await screen.findByRole('combobox', {name: labels.account}), '8');
      await waitFor(() => expect(fetch.mock.lastCall[0]).toContain('authentication_id=8'));
    });

    it('switches back to Flickr', async () => {
      const user = userEvent.setup();
      open();
      await user.selectOptions(await screen.findByRole('combobox', {name: labels.source}), 'flickr');
      await waitFor(() => expect(fetch.mock.lastCall[0]).toContain('source=flickr'));
    });

    it('offers both sources when both are connected', async () => {
      open();
      const select = await screen.findByRole('combobox', {name: labels.source});
      expect(Array.from(select.options, (option) => option.value)).toEqual(['flickr', 'mastodon']);
    });

    it('does not offer Flickr when only Mastodon is connected', async () => {
      mastodonData.sources = ['mastodon'];
      open();
      await screen.findByRole('button', {name: photo.title});
      expect(screen.queryByRole('option', {name: labels.flickr})).not.toBeInTheDocument();
    });

    it('uses a single connected source without a source selector', async () => {
      mastodonData.sources = ['mastodon'];
      open();
      await screen.findByRole('button', {name: photo.title});
      expect(screen.queryByRole('combobox', {name: labels.source})).not.toBeInTheDocument();
    });

    it('does not offer Mastodon when only Flickr is connected', async () => {
      fetch.mockResolvedValue({ok: true, json: async () => ({...ready, source: 'flickr', sources: ['flickr'], labels})});
      render(<AddPhotoModal label="Tomatoes" newUrl="/photos/new?type=job&id=5" onClose={vi.fn()} onAdded={vi.fn()} />);
      await screen.findByRole('button', {name: photo.title});
      expect(screen.queryByRole('option', {name: labels.mastodon})).not.toBeInTheDocument();
    });

    it('lets the server choose the initially connected source', async () => {
      fetch.mockResolvedValue({ok: true, json: async () => ({...mastodonData, sources: ['mastodon']})});
      render(<AddPhotoModal label="Tomatoes" newUrl="/photos/new?type=job&id=5" onClose={vi.fn()} onAdded={vi.fn()} />);
      await screen.findByRole('button', {name: photo.title});
      expect(fetch.mock.calls[0][0]).not.toContain('source=');
    });

    it('imports from the source automatically selected by the server', async () => {
      fetch.mockImplementation(async (url) => ({ok: true, status: 200,
        json: async () => url.startsWith('/photos/new') ? {...mastodonData, sources: ['mastodon']} : {}}));
      const user = userEvent.setup();
      render(<AddPhotoModal label="Tomatoes" newUrl="/photos/new?type=job&id=5" onClose={vi.fn()} onAdded={vi.fn()} />);
      await user.click(await screen.findByRole('button', {name: photo.title}));
      await user.click(screen.getByRole('checkbox'));
      await user.click(screen.getByRole('button', {name: labels.add}));
      expect(JSON.parse(fetch.mock.lastCall[1].body).photo.source).toBe('mastodon');
    });
  });
});
