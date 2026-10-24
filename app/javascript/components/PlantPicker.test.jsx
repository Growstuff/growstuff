import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PlantPicker from './PlantPicker';

vi.mock('./PlantSomethingModal', () => ({
  default: ({garden, crop}) => <div role="dialog" aria-label={`${garden.name} ${crop ? crop.name : 'no crop'}`} />,
}));

describe('PlantPicker', () => {
  it('starts closed', () => {
    render(<PlantPicker label="Plant" garden={{name: 'Yard'}} />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens the dialog for the garden', async () => {
    render(<PlantPicker label="Plant" garden={{name: 'Yard'}} />);
    await userEvent.click(screen.getByRole('button', {name: 'Plant'}));
    expect(screen.getByRole('dialog', {name: 'Yard no crop'})).toBeInTheDocument();
  });

  it('opens with the crop already chosen', async () => {
    render(<PlantPicker label="Plant" garden={{name: 'Yard'}} crop={{name: 'Kale'}} />);
    await userEvent.click(screen.getByRole('button', {name: 'Plant'}));
    expect(screen.getByRole('dialog', {name: 'Yard Kale'})).toBeInTheDocument();
  });
});
