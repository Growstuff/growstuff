import {render, screen} from '@testing-library/react';
import {describe, expect, it, vi} from 'vitest';

import SeedPacket from './SeedPacket';

function stubCropPhoto(photoUrl) {
  const fetch = vi.fn(async () => ({ok: true, status: 200, json: async () => ({photo_url: photoUrl})}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

describe('SeedPacket', () => {
  it('names the packet', () => {
    stubCropPhoto(null);
    render(<SeedPacket packet={{id: 1, name: 'Roma tomato', photo_url: '/own.jpg', crop_slug: 'tomato'}} />);
    expect(screen.getByText('Roma tomato', {selector: 'figcaption'})).toBeInTheDocument();
  });

  describe('with its own photo', () => {
    it('shows it', () => {
      stubCropPhoto('/crop.jpg');
      render(<SeedPacket packet={{id: 1, name: 'Roma tomato', photo_url: '/own.jpg', crop_slug: 'tomato'}} />);
      expect(screen.getByAltText('Photo of Roma tomato')).toHaveAttribute('src', '/own.jpg');
    });

    it('does not fetch the crop\'s', () => {
      const fetch = stubCropPhoto('/crop.jpg');
      render(<SeedPacket packet={{id: 1, name: 'Roma tomato', photo_url: '/own.jpg', crop_slug: 'tomato'}} />);
      expect(fetch).not.toHaveBeenCalled();
    });
  });

  describe('without a photo', () => {
    it('shows the crop\'s photo', async () => {
      stubCropPhoto('/crop.jpg');
      render(<SeedPacket packet={{id: 1, name: 'Roma tomato', photo_url: null, crop_slug: 'tomato'}} />);
      expect(await screen.findByAltText('Photo of Roma tomato')).toHaveAttribute('src', '/crop.jpg');
    });

    it('shows no photo while it is fetched', () => {
      stubCropPhoto('/crop.jpg');
      render(<SeedPacket packet={{id: 1, name: 'Roma tomato', photo_url: null, crop_slug: 'tomato'}} />);
      expect(screen.queryByRole('img')).not.toBeInTheDocument();
    });
  });
});
