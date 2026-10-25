import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PlantingPicker from './PlantingPicker';

vi.mock('./RecordHarvestModal', () => ({
  default: ({planting}) => <div role="dialog" aria-label={`Harvest ${planting.crop.name}`} />,
}));
vi.mock('./SaveSeedsModal', () => ({
  default: ({planting}) => <div role="dialog" aria-label={`Seeds ${planting.crop.name}`} />,
}));

const plantings = [
  {id: 1, crop: {name: 'Tomato'}, ready: true},
  {id: 2, crop: {name: 'Kale'}, ready: false},
];

async function open(action, list = plantings) {
  render(<PlantingPicker action={action} label="Go" plantings={list} />);
  await userEvent.click(screen.getByRole('button', {name: 'Go'}));
}

describe('PlantingPicker', () => {
  it('starts closed', () => {
    render(<PlantingPicker action="harvest" label="Go" plantings={plantings} />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('asks what was harvested', async () => {
    await open('harvest');
    expect(screen.getByRole('dialog', {name: 'What did you harvest?'})).toBeInTheDocument();
  });

  it('asks which plant to save seeds from', async () => {
    await open('seeds');
    expect(screen.getByRole('dialog', {name: 'Which plant are you saving seeds from?'})).toBeInTheDocument();
  });

  it('lists the plantings', async () => {
    await open('harvest');
    expect(screen.getAllByRole('button', {name: /Tomato|Kale/})).toHaveLength(2);
  });

  it('shows the garden', async () => {
    await open('seeds', [{id: 1, crop: {name: 'Tomato'}, garden: 'Back bed'}]);
    expect(screen.getByText('Back bed')).toBeInTheDocument();
  });

  it('offers something else when harvesting', async () => {
    await open('harvest');
    expect(screen.getByRole('button', {name: 'Something else'})).toBeInTheDocument();
  });

  it('offers something else when saving seeds', async () => {
    await open('seeds');
    expect(screen.getByRole('button', {name: 'Something else'})).toBeInTheDocument();
  });

  it('uses small tiles for more than twelve plantings', async () => {
    const many = Array.from({length: 13}, (_, index) => ({id: index, crop: {name: `Crop ${index}`}}));
    await open('harvest', many);
    expect(screen.getByRole('group', {name: 'Your plantings'})).toHaveClass('planting-tiles-small');
  });

  it('badges what is ready', async () => {
    await open('harvest');
    expect(screen.getByText('ready')).toBeInTheDocument();
  });

  it('opens the harvest dialog for the chosen planting', async () => {
    await open('harvest');
    await userEvent.click(screen.getByRole('button', {name: /Kale/}));
    expect(screen.getByRole('dialog', {name: 'Harvest Kale'})).toBeInTheDocument();
  });

  it('opens the seeds dialog for the chosen planting', async () => {
    await open('seeds');
    await userEvent.click(screen.getByRole('button', {name: /Tomato/}));
    expect(screen.getByRole('dialog', {name: 'Seeds Tomato'})).toBeInTheDocument();
  });

  it('cancels', async () => {
    await open('harvest');
    await userEvent.click(screen.getByRole('button', {name: 'Cancel'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  describe('with nothing growing', () => {
    it('says to plant something first', async () => {
      await open('harvest', []);
      expect(screen.getByText(/nothing growing yet/)).toBeInTheDocument();
    });
  });
});
