import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PlantingRating from './PlantingRating';

const planting = {id: 7, url: '/plantings/7'};

function stubFetch(ok) {
  const fetch = vi.fn(async () => ({ok, status: ok ? 200 : 500, json: async () => ({})}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

const star = (number) => screen.getByLabelText(`${number} of 5`, {exact: false, selector: 'input'});

describe('PlantingRating', () => {
  it('shows the current rating', () => {
    stubFetch(true);
    render(<PlantingRating planting={planting} value={4} />);
    expect(star(4)).toBeChecked();
  });

  it('shows no rating when there is none', () => {
    stubFetch(true);
    render(<PlantingRating planting={planting} />);
    expect(screen.getByText('Not rated')).toBeInTheDocument();
  });

  describe('when a star is clicked', () => {
    it('patches the planting with the rating', async () => {
      const fetch = stubFetch(true);
      render(<PlantingRating planting={planting} value={null} />);
      await userEvent.click(star(5));
      expect(fetch).toHaveBeenCalledWith('/plantings/7', expect.objectContaining({
        method: 'PATCH',
        body: JSON.stringify({planting: {overall_rating: 5}}),
      }));
    });

    it('shows the new rating', async () => {
      stubFetch(true);
      render(<PlantingRating planting={planting} value={null} />);
      await userEvent.click(star(5));
      expect(star(5)).toBeChecked();
    });
  });

  describe('when the save fails', () => {
    it('goes back to the old rating', async () => {
      stubFetch(false);
      render(<PlantingRating planting={planting} value={2} />);
      await userEvent.click(star(5));
      await waitFor(() => expect(star(2)).toBeChecked());
    });

    it('says the rating did not save', async () => {
      stubFetch(false);
      render(<PlantingRating planting={planting} value={2} />);
      await userEvent.click(star(5));
      expect(await screen.findByRole('alert')).toHaveTextContent('didn’t save');
    });
  });
});
