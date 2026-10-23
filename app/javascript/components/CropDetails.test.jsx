import {render, screen} from '@testing-library/react';
import {describe, expect, it, vi} from 'vitest';

import CropDetails from './CropDetails';

const info = {
  name: 'Tomato', scientific_name: 'Solanum lycopersicum', parent_name: null, description: 'Red and juicy.',
  photo_url: '/tomato.jpg', perennial: false, sun: 'full sun', sowing_method: 'indoors', days_to_harvest: 80,
  row_spacing_cm: 50, spread_cm: null, height_cm: 120, usually_from: 'seed',
  grown_by: 3, your_plantings: 2, your_seeds: 1, url: '/crops/tomato',
};

function stubInfo(data, ok = true) {
  const fetch = vi.fn(async () => ({ok, status: ok ? 200 : 404, json: async () => data}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

describe('CropDetails', () => {
  it('asks for the crop\'s sowing info', async () => {
    const fetch = stubInfo(info);
    render(<CropDetails slug="tomato" />);
    await screen.findByText('Tomato');
    expect(fetch).toHaveBeenCalledWith('/crops/tomato/sowing_info.json', expect.anything());
  });

  it('shows the name', async () => {
    stubInfo(info);
    render(<CropDetails slug="tomato" />);
    expect(await screen.findByRole('heading', {name: 'Tomato'})).toBeInTheDocument();
  });

  it('shows the photo', async () => {
    stubInfo(info);
    render(<CropDetails slug="tomato" />);
    expect(await screen.findByAltText('Photo of Tomato')).toHaveAttribute('src', '/tomato.jpg');
  });

  it('shows how it grows', async () => {
    stubInfo(info);
    render(<CropDetails slug="tomato" />);
    expect(await screen.findByText('Annual')).toBeInTheDocument();
  });

  it('adds units to sizes', async () => {
    stubInfo(info);
    render(<CropDetails slug="tomato" />);
    expect(await screen.findByText('120 cm')).toBeInTheDocument();
  });

  it('leaves out facts it does not have', async () => {
    stubInfo(info);
    render(<CropDetails slug="tomato" />);
    await screen.findByText('Annual');
    expect(screen.queryByText('Spread')).not.toBeInTheDocument();
  });

  it('says how often you have grown it', async () => {
    stubInfo(info);
    render(<CropDetails slug="tomato" />);
    expect(await screen.findByText(/You have grown it 2 times/)).toBeInTheDocument();
  });

  it('says how many packets you have, singular', async () => {
    stubInfo(info);
    render(<CropDetails slug="tomato" />);
    expect(await screen.findByText(/You have 1 packet of its seeds/)).toBeInTheDocument();
  });

  it('links to the crop page', async () => {
    stubInfo(info);
    render(<CropDetails slug="tomato" />);
    expect(await screen.findByRole('link', {name: 'More about Tomato'})).toHaveAttribute('href', '/crops/tomato');
  });

  describe('for a kind of another crop', () => {
    it('names the parent', async () => {
      stubInfo({...info, parent_name: 'Nightshade'});
      render(<CropDetails slug="tomato" />);
      expect(await screen.findByText('A kind of Nightshade')).toBeInTheDocument();
    });
  });

  describe('for a perennial', () => {
    it('says it comes back each year', async () => {
      stubInfo({...info, perennial: true});
      render(<CropDetails slug="tomato" />);
      expect(await screen.findByText('Perennial, comes back each year')).toBeInTheDocument();
    });
  });

  describe('when the crop cannot be found', () => {
    it('draws nothing', async () => {
      const fetch = stubInfo({}, false);
      const {container} = render(<CropDetails slug="nope" />);
      await vi.waitFor(() => expect(fetch).toHaveBeenCalled());
      expect(container).toBeEmptyDOMElement();
    });
  });
});
