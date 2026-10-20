import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it} from 'vitest';

import NameFields from './NameFields';

function setup(names) {
  const user = userEvent.setup();
  render(
      <NameFields
        names={names}
        field="alt_name"
        noun="Alternate name"
        buttonClass="altname"
        help="Alternate name of crop."
        renderInput={({id, name, value, onChange}) => (
          <input id={id} name={name} value={value} onChange={(event) => onChange(event.target.value)} />
        )}
      />,
  );
  return user;
}

const field = (number) => screen.getByLabelText(`Alternate name ${number}:`);

describe('NameFields', () => {
  it('shows a field for each name', () => {
    setup(['Sampaguita', 'Manol']);
    expect(screen.getAllByRole('textbox')).toHaveLength(2);
  });

  it('fills each field with its name', () => {
    setup(['Sampaguita', 'Manol']);
    expect(field(2)).toHaveValue('Manol');
  });

  it('names the fields the way the controller reads them', () => {
    setup(['Sampaguita']);
    expect(field(1)).toHaveAttribute('name', 'alt_name[1]');
  });

  it('shows one empty field when there are no names', () => {
    setup([]);
    expect(field(1)).toHaveValue('');
  });

  it('shows an empty field for a blank name from a new crop', () => {
    setup([null]);
    expect(field(1)).toHaveValue('');
  });

  it('adds a field', async () => {
    const user = setup(['Sampaguita']);
    await user.click(screen.getByRole('button', {name: 'Add alternate name'}));
    expect(field(2)).toHaveValue('');
  });

  it('keeps what was typed when a field is added', async () => {
    const user = setup(['']);
    await user.type(field(1), 'Manol');
    await user.click(screen.getByRole('button', {name: 'Add alternate name'}));
    expect(field(1)).toHaveValue('Manol');
  });

  it('removes the chosen field, not the last', async () => {
    const user = setup(['Sampaguita', 'Manol']);
    await user.click(screen.getByRole('button', {name: 'Remove alternate name 1'}));
    expect(field(1)).toHaveValue('Manol');
  });

  it('renumbers the fields after one is removed', async () => {
    const user = setup(['Sampaguita', 'Manol']);
    await user.click(screen.getByRole('button', {name: 'Remove alternate name 1'}));
    expect(screen.queryByLabelText('Alternate name 2:')).not.toBeInTheDocument();
  });

  it('cannot remove the only field', () => {
    setup(['Sampaguita']);
    expect(screen.getByRole('button', {name: 'Remove alternate name 1'})).toBeDisabled();
  });

  it('gives the buttons classes to find them by', () => {
    setup(['Sampaguita']);
    expect(screen.getByRole('button', {name: 'Add alternate name'})).toHaveClass('add-altname-row');
  });

  it('shows the help text', () => {
    setup(['Sampaguita']);
    expect(screen.getByText('Alternate name of crop.')).toBeInTheDocument();
  });
});
