import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import GardenPlanter from './GardenPlanter';

vi.mock('./PlantSomethingModal', () => ({
  default: ({garden, onClose}) => (
    <div role="dialog" aria-label={`Plant something in ${garden.name}`}><button type="button" onClick={onClose}>Close</button></div>
  ),
}));

const garden = {id: 1, name: 'Orchard'};

describe('GardenPlanter', () => {
  it('shows the button', () => {
    render(<GardenPlanter garden={garden} buttonClass="btn btn-sm section-add" />);
    expect(screen.getByRole('button', {name: 'add'})).toHaveClass('section-add');
  });

  it('starts closed', () => {
    render(<GardenPlanter garden={garden} />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens the plant something dialog for the garden', async () => {
    render(<GardenPlanter garden={garden} />);
    await userEvent.click(screen.getByRole('button', {name: 'add'}));
    expect(screen.getByRole('dialog', {name: 'Plant something in Orchard'})).toBeInTheDocument();
  });

  it('closes it again', async () => {
    render(<GardenPlanter garden={garden} />);
    await userEvent.click(screen.getByRole('button', {name: 'add'}));
    await userEvent.click(screen.getByRole('button', {name: 'Close'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
