import {render, screen} from '@testing-library/react';
import {describe, expect, it} from 'vitest';

import CropChip from './CropChip';

const crop = {name: 'Tomato', icon_url: '/tomato.png'};

function setup(props = {}) {
  return render(<CropChip url="/plantings/1" crop={crop} defaultIconUrl="/default.png" {...props} />);
}

describe('CropChip', () => {
  it('links to the planting', () => {
    setup();
    expect(screen.getByRole('link')).toHaveAttribute('href', '/plantings/1');
  });

  it('shows the crop name', () => {
    setup();
    expect(screen.getByRole('link')).toHaveTextContent('Tomato');
  });

  it('uses the crop icon', () => {
    setup();
    expect(screen.getByAltText('Tomato')).toHaveAttribute('src', '/tomato.png');
  });

  describe('without a crop icon', () => {
    it('uses the default icon', () => {
      setup({crop: {name: 'Tomato'}});
      expect(screen.getByAltText('Tomato')).toHaveAttribute('src', '/default.png');
    });
  });

  describe('when highlighted', () => {
    it('marks the chip as just added', () => {
      const {container} = setup({highlighted: true});
      expect(container.querySelector('.chip')).toHaveClass('planting-just-added');
    });
  });

  describe('when not highlighted', () => {
    it('does not mark the chip as just added', () => {
      const {container} = setup();
      expect(container.querySelector('.chip')).not.toHaveClass('planting-just-added');
    });
  });
});
