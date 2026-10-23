import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PlantPartPicker from './PlantPartPicker';

const parts = [
  {id: 1, name: 'fruit', icon_url: '/fruit.png'},
  {id: 2, name: 'leaf'},
  {id: 3, name: 'root fruit'},
];

function setup(props = {}) {
  const onChoose = vi.fn();
  render(<PlantPartPicker id="part" parts={parts} suggestedId={2} onChoose={onChoose} {...props} />);
  return onChoose;
}

const names = () => screen.getAllByRole('option').map((option) => option.textContent);

describe('PlantPartPicker', () => {
  it('asks what part was harvested', () => {
    setup();
    expect(screen.getByRole('combobox', {name: 'What part did you harvest?'})).toBeInTheDocument();
  });

  it('lists every part to start with', () => {
    setup();
    expect(screen.getAllByRole('option')).toHaveLength(3);
  });

  it('puts the usual part first', () => {
    setup();
    expect(names()[0]).toMatch(/^leaf/);
  });

  it('says which part is usual', () => {
    setup();
    expect(screen.getByText(/usual for this crop/)).toBeInTheDocument();
  });

  it('narrows the list as you type', async () => {
    setup();
    await userEvent.type(screen.getByRole('combobox'), 'leaf');
    expect(screen.getAllByRole('option')).toHaveLength(1);
  });

  it('puts parts that start with the text before ones that contain it', async () => {
    setup();
    await userEvent.type(screen.getByRole('combobox'), 'fruit');
    expect(names()).toEqual(['fruit', 'root fruit']);
  });

  it('says when nothing matches', async () => {
    setup();
    await userEvent.type(screen.getByRole('combobox'), 'zzz');
    expect(screen.getByText(/No plant parts match/)).toBeInTheDocument();
  });

  it('chooses a part by clicking it', async () => {
    const onChoose = setup();
    await userEvent.click(screen.getByRole('option', {name: 'fruit'}));
    expect(onChoose).toHaveBeenCalledWith(parts[0]);
  });

  it('chooses the top match with Enter', async () => {
    const onChoose = setup();
    await userEvent.type(screen.getByRole('combobox'), 'root{Enter}');
    expect(onChoose).toHaveBeenCalledWith(parts[2]);
  });

  it('chooses the highlighted part with the arrow keys and Enter', async () => {
    const onChoose = setup();
    await userEvent.type(screen.getByRole('combobox'), '{ArrowDown}{ArrowDown}{Enter}');
    expect(onChoose).toHaveBeenCalledWith(parts[0]);
  });

  it('wraps from the top up to the bottom', async () => {
    const onChoose = setup();
    await userEvent.type(screen.getByRole('combobox'), '{ArrowDown}{ArrowUp}{Enter}');
    expect(onChoose).toHaveBeenCalledWith(parts[2]);
  });

  it('closes the list on Escape', async () => {
    setup();
    await userEvent.type(screen.getByRole('combobox'), '{Escape}');
    expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
  });

  it('reopens the list with the down arrow', async () => {
    setup();
    await userEvent.type(screen.getByRole('combobox'), '{Escape}{ArrowDown}');
    expect(screen.getByRole('listbox')).toBeInTheDocument();
  });
});
