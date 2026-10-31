import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import LocationPicker from './LocationPicker';

const places = [{name: 'Wellington, NZ', latitude: -41.3, longitude: 174.8}, {name: 'Wellington, UK', latitude: 52.7, longitude: -2.5}];

function stubFetch(...replies) {
  const fetch = vi.fn();
  replies.forEach((reply) => fetch.mockResolvedValueOnce({ok: reply.ok ?? true, status: reply.status ?? 200, json: async () => reply.data ?? {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

async function open() {
  render(<LocationPicker label="Set location" searchUrl="/places" saveUrl="/location" />);
  await userEvent.click(screen.getByRole('button', {name: 'Set location'}));
}

async function search(text) {
  await userEvent.type(screen.getByLabelText('City or region'), text);
  await userEvent.click(screen.getByRole('button', {name: 'Search'}));
}

describe('LocationPicker', () => {
  it('starts closed', () => {
    render(<LocationPicker label="Set location" searchUrl="/places" saveUrl="/location" />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens the dialog', async () => {
    await open();
    expect(screen.getByRole('dialog', {name: 'Tell us where you garden'})).toBeInTheDocument();
  });

  it('cannot save before a place is chosen', async () => {
    await open();
    expect(screen.getByRole('button', {name: 'Save location'})).toBeDisabled();
  });

  it('asks for more when the search is too short', async () => {
    await open();
    await search('W');
    expect(screen.getByText('Type a city or region to search for.')).toBeInTheDocument();
  });

  it('searches for the text', async () => {
    const fetch = stubFetch({data: places});
    await open();
    await search('Wellington');
    expect(fetch).toHaveBeenCalledWith('/places?q=Wellington', expect.anything());
  });

  it('lists the places found', async () => {
    stubFetch({data: places});
    await open();
    await search('Wellington');
    expect(await screen.findAllByRole('radio')).toHaveLength(2);
  });

  it('chooses the only place found', async () => {
    stubFetch({data: [places[0]]});
    await open();
    await search('Wellington');
    expect(await screen.findByRole('radio', {name: 'Wellington, NZ'})).toBeChecked();
  });

  it('says when nothing is found', async () => {
    stubFetch({data: []});
    await open();
    await search('Nowhere');
    expect(await screen.findByText(/couldn't find that/)).toBeInTheDocument();
  });

  it('says when the search fails', async () => {
    stubFetch({ok: false, status: 500});
    await open();
    await search('Wellington');
    expect(await screen.findByText(/couldn't search for places/)).toBeInTheDocument();
  });

  it('saves the chosen place', async () => {
    const fetch = stubFetch({data: places}, {data: {}});
    vi.stubGlobal('location', {...window.location, reload: vi.fn()});
    await open();
    await search('Wellington');
    await userEvent.click(await screen.findByRole('radio', {name: 'Wellington, UK'}));
    await userEvent.click(screen.getByRole('button', {name: 'Save location'}));
    expect(fetch).toHaveBeenLastCalledWith('/location', expect.objectContaining({
      method: 'PATCH',
      body: JSON.stringify({location: {name: 'Wellington, UK', latitude: 52.7, longitude: -2.5}}),
    }));
  });

  it('says when saving fails', async () => {
    stubFetch({data: [places[0]]}, {ok: false, status: 500});
    await open();
    await search('Wellington');
    await screen.findByRole('radio');
    await userEvent.click(screen.getByRole('button', {name: 'Save location'}));
    expect(await screen.findByText(/Something went wrong saving that/)).toBeInTheDocument();
  });

  it('searches near the browser\'s location', async () => {
    const fetch = stubFetch({data: places});
    vi.stubGlobal('navigator', {...navigator, geolocation: {getCurrentPosition: (ok) => ok({coords: {latitude: 1, longitude: 2}})}});
    await open();
    await userEvent.click(screen.getByRole('button', {name: 'Use my current location'}));
    expect(fetch).toHaveBeenCalledWith('/places?lat=1&lng=2', expect.anything());
  });

  it('says when the browser cannot share its location', async () => {
    vi.stubGlobal('navigator', {...navigator, geolocation: undefined});
    await open();
    await userEvent.click(screen.getByRole('button', {name: 'Use my current location'}));
    expect(screen.getByText(/browser can't share its location/)).toBeInTheDocument();
  });

  it('closes with Cancel', async () => {
    await open();
    await userEvent.click(screen.getByRole('button', {name: 'Cancel'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  describe('for a garden', () => {
    const profilePlace = {name: 'Wellington, NZ', latitude: -41.3, longitude: 174.8};

    async function openForGarden(props = {}) {
      render(
        <LocationPicker label="Set location" searchUrl="/places" saveUrl="/gardens/g/location"
          title="Where is this garden?" intro="Shows the weather here." {...props} />
      );
      await userEvent.click(screen.getByRole('button', {name: 'Set location'}));
    }

    it('uses the title it is given', async () => {
      await openForGarden();
      expect(screen.getByRole('dialog', {name: 'Where is this garden?'})).toBeInTheDocument();
    });

    it('uses the intro it is given', async () => {
      await openForGarden();
      expect(screen.getByText('Shows the weather here.')).toBeInTheDocument();
    });

    it('offers no profile place without one', async () => {
      await openForGarden();
      expect(screen.queryByRole('button', {name: /from my profile/})).not.toBeInTheDocument();
    });

    it('offers the profile place when there is one', async () => {
      await openForGarden({profilePlace});
      expect(screen.getByRole('button', {name: 'Use Wellington, NZ from my profile'})).toBeInTheDocument();
    });

    it('chooses the profile place ready to save', async () => {
      await openForGarden({profilePlace});
      await userEvent.click(screen.getByRole('button', {name: 'Use Wellington, NZ from my profile'}));
      expect(screen.getByRole('button', {name: 'Save location'})).toBeEnabled();
    });

    it('saves the profile place to the garden', async () => {
      const fetch = stubFetch({data: {}});
      vi.stubGlobal('location', {...window.location, reload: vi.fn()});
      await openForGarden({profilePlace});
      await userEvent.click(screen.getByRole('button', {name: 'Use Wellington, NZ from my profile'}));
      await userEvent.click(screen.getByRole('button', {name: 'Save location'}));
      expect(fetch).toHaveBeenCalledWith('/gardens/g/location', expect.objectContaining({method: 'PATCH'}));
    });
  });
});
