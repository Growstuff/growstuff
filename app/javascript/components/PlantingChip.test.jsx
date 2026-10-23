import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PlantingChip from './PlantingChip';

const crop = {name: 'Tomato', icon_url: '/tomato.png'};
const actions = [{key: 'edit', label: 'Edit', href: '/plantings/1/edit'}, {key: 'show', label: 'View', href: '/plantings/1'}];
const planting = {id: 1, url: '/plantings/1', crop, actions};

describe('PlantingChip', () => {
  describe('with actions', () => {
    it('is a menu for the planting', () => {
      render(<PlantingChip planting={planting} defaultIconUrl="/d.png" handlers={{}} />);
      expect(screen.getByRole('button', {name: 'Actions for Tomato'})).toBeInTheDocument();
    });

    it('lists the actions', () => {
      render(<PlantingChip planting={planting} defaultIconUrl="/d.png" handlers={{}} />);
      expect(screen.getByRole('link', {name: 'View'})).toBeInTheDocument();
    });

    it('opens the dialog for an action that has one', async () => {
      const edit = vi.fn();
      render(<PlantingChip planting={planting} defaultIconUrl="/d.png" handlers={{edit}} />);
      await userEvent.click(screen.getByRole('link', {name: 'Edit'}));
      expect(edit).toHaveBeenCalledWith(planting, actions[0]);
    });

    it('marks a highlighted chip', () => {
      render(<PlantingChip planting={planting} defaultIconUrl="/d.png" highlighted handlers={{}} />);
      expect(screen.getByRole('button')).toHaveClass('planting-just-added');
    });
  });

  describe('without actions', () => {
    it('is a plain link to the planting', () => {
      render(<PlantingChip planting={{...planting, actions: []}} defaultIconUrl="/d.png" handlers={{}} />);
      expect(screen.getByRole('link')).toHaveAttribute('href', '/plantings/1');
    });
  });
});
