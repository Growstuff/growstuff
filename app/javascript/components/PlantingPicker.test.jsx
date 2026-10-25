import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PlantingPicker from './PlantingPicker';

vi.mock('./CropPicker', () => ({
  default: ({onChoose}) => <button type="button" onClick={() => onChoose({id: 9, name: 'Kale'})}>Choose Kale</button>,
}));

vi.mock('./RecordHarvestModal', () => ({
  default: ({planting, crop}) => <div role="dialog" aria-label={`Harvest ${(planting || {crop}).crop.name}`} />,
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

  it('asks if the seeds were saved from a plant', async () => {
    await open('seeds');
    expect(screen.getByRole('dialog', {name: 'Where did these seeds come from?'})).toBeInTheDocument();
  });

  it('asks which plant to save seeds from', async () => {
    await open('seeds');
    await userEvent.click(screen.getByRole('button', {name: 'Seeds I saved from my plants'}));
    expect(screen.getByRole('dialog', {name: 'Which plant are you saving seeds from?'})).toBeInTheDocument();
  });

  it('lists the plantings', async () => {
    await open('harvest');
    expect(screen.getAllByRole('button', {name: /Tomato|Kale/})).toHaveLength(2);
  });

  it('shows the garden', async () => {
    await open('seeds', [{id: 1, crop: {name: 'Tomato'}, garden: 'Back bed'}]);
    await userEvent.click(screen.getByRole('button', {name: 'Seeds I saved from my plants'}));
    expect(screen.getByText('Back bed')).toBeInTheDocument();
  });

  it('offers something else when harvesting', async () => {
    await open('harvest');
    expect(screen.getByRole('button', {name: 'Something else'})).toBeInTheDocument();
  });

  it('stays in the dialog for a crop that is not in the list', async () => {
    await open('harvest');
    await userEvent.click(screen.getByRole('button', {name: 'Something else'}));
    await userEvent.click(screen.getByRole('button', {name: 'Choose Kale'}));
    expect(screen.getByRole('dialog', {name: 'Harvest Kale'})).toBeInTheDocument();
  });

  it('asks for the crop when the seeds were not saved from a plant', async () => {
    await open('seeds');
    await userEvent.click(screen.getByRole('button', {name: 'Seeds I bought'}));
    expect(screen.getByRole('dialog', {name: 'Which seeds are you adding?'})).toBeInTheDocument();
  });

  it('does not offer something else when saving seeds from a plant', async () => {
    await open('seeds');
    await userEvent.click(screen.getByRole('button', {name: 'Seeds I saved from my plants'}));
    expect(screen.queryByRole('button', {name: 'Something else'})).not.toBeInTheDocument();
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
    await userEvent.click(screen.getByRole('button', {name: 'Seeds I saved from my plants'}));
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
