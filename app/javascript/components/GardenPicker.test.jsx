import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import GardenPicker from './GardenPicker';

vi.mock('./GardenFormModal', () => ({
  default: ({onClose}) => <div role="dialog" aria-label="New garden"><button type="button" onClick={onClose}>Close</button></div>,
}));

describe('GardenPicker', () => {
  it('shows the button', () => {
    render(<GardenPicker label="Add a garden" buttonClass="big" />);
    expect(screen.getByRole('button', {name: 'Add a garden'})).toHaveClass('big');
  });

  it('starts closed', () => {
    render(<GardenPicker label="Add a garden" />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens the new garden dialog', async () => {
    render(<GardenPicker label="Add a garden" />);
    await userEvent.click(screen.getByRole('button', {name: 'Add a garden'}));
    expect(screen.getByRole('dialog', {name: 'New garden'})).toBeInTheDocument();
  });

  it('closes it again', async () => {
    render(<GardenPicker label="Add a garden" />);
    await userEvent.click(screen.getByRole('button', {name: 'Add a garden'}));
    await userEvent.click(screen.getByRole('button', {name: 'Close'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
