import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import AddSeedsPicker from './AddSeedsPicker';

vi.mock('./CropPicker', () => ({
  default: ({onChoose}) => <button type="button" onClick={() => onChoose({id: 3, name: 'Kale'})}>Choose Kale</button>,
}));
vi.mock('./SaveSeedsModal', () => ({
  default: ({crop}) => <div role="dialog" aria-label={`Seeds ${crop.name}`} />,
}));

describe('AddSeedsPicker', () => {
  it('asks which seeds', async () => {
    render(<AddSeedsPicker label="+ seeds" />);
    await userEvent.click(screen.getByRole('button', {name: '+ seeds'}));
    expect(screen.getByRole('dialog', {name: 'Add seeds'})).toBeInTheDocument();
  });

  it('opens the save seeds dialog for the chosen crop', async () => {
    render(<AddSeedsPicker label="+ seeds" />);
    await userEvent.click(screen.getByRole('button', {name: '+ seeds'}));
    await userEvent.click(screen.getByRole('button', {name: 'Choose Kale'}));
    expect(screen.getByRole('dialog', {name: 'Seeds Kale'})).toBeInTheDocument();
  });
});
