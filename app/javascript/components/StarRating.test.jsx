import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import StarRating from './StarRating';

function setup(value) {
  const onChange = vi.fn();
  render(<StarRating id="rate" label="Rating" value={value} onChange={onChange} />);
  return onChange;
}

describe('StarRating', () => {
  it('has five stars', () => {
    setup(null);
    expect(screen.getAllByRole('radio')).toHaveLength(5);
  });

  it('checks the star for the value', () => {
    setup(3);
    expect(screen.getByRole('radio', {name: '3 of 5'})).toBeChecked();
  });

  it('says the value', () => {
    setup(4);
    expect(screen.getByText('4 of 5', {selector: '.star-rating-value'})).toBeInTheDocument();
  });

  it('reports the star clicked', async () => {
    const onChange = setup(null);
    await userEvent.click(screen.getByLabelText('2 of 5'));
    expect(onChange).toHaveBeenCalledWith(2);
  });

  describe('without a rating', () => {
    it('says it is not rated', () => {
      setup(null);
      expect(screen.getByText('Not rated')).toBeInTheDocument();
    });

    it('has no Clear button', () => {
      setup(null);
      expect(screen.queryByRole('button', {name: 'Clear'})).not.toBeInTheDocument();
    });
  });

  describe('with a rating', () => {
    it('clears it to null', async () => {
      const onChange = setup(3);
      await userEvent.click(screen.getByRole('button', {name: 'Clear'}));
      expect(onChange).toHaveBeenCalledWith(null);
    });

    it('lights the stars up to the value', () => {
      const {container} = render(<StarRating id="x" label="Rating" value={2} onChange={vi.fn()} />);
      expect(container.querySelectorAll('.star-rating-star--lit')).toHaveLength(2);
    });
  });

  describe('when hovering a star', () => {
    it('lights the stars up to it', async () => {
      const {container} = render(<StarRating id="x" label="Rating" value={1} onChange={vi.fn()} />);
      await userEvent.hover(container.querySelector('label[for="x-4"]'));
      expect(container.querySelectorAll('.star-rating-star--lit')).toHaveLength(4);
    });
  });
});
