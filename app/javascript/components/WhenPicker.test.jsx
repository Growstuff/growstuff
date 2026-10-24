import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import {formatDate} from '../dates';
import WhenPicker from './WhenPicker';

function setup(props = {}) {
  const onWhen = vi.fn();
  const onDate = vi.fn();
  render(<WhenPicker id="w" legend="When?" when="today" onWhen={onWhen} date="" onDate={onDate} {...props} />);
  return {onWhen, onDate};
}

describe('WhenPicker', () => {
  it('is a group with the legend', () => {
    setup();
    expect(screen.getByRole('group', {name: 'When?'})).toBeInTheDocument();
  });

  it('offers today, yesterday and a date', () => {
    setup();
    expect(screen.getAllByRole('radio')).toHaveLength(3);
  });

  it('checks the current choice', () => {
    setup({when: 'yesterday'});
    expect(screen.getByLabelText('Yesterday')).toBeChecked();
  });

  it('reports the choice made', async () => {
    const {onWhen} = setup();
    await userEvent.click(screen.getByLabelText('Yesterday'));
    expect(onWhen).toHaveBeenCalledWith('yesterday');
  });

  it('can leave out yesterday', () => {
    setup({choices: [['today', 'Today'], ['other', 'Enter date']]});
    expect(screen.queryByLabelText('Yesterday')).not.toBeInTheDocument();
  });

  it('shows the date the choice means', () => {
    setup({hint: '2020-03-05'});
    expect(screen.getByText(formatDate('2020-03-05'))).toBeInTheDocument();
  });

  it('has no date box for today', () => {
    setup();
    expect(screen.queryByLabelText('Date')).not.toBeInTheDocument();
  });

  describe('when entering a date', () => {
    it('shows the date box', () => {
      setup({when: 'other', date: '2020-03-05'});
      expect(screen.getByLabelText('Date')).toHaveValue('2020-03-05');
    });

    it('limits the date box', () => {
      setup({when: 'other', min: '2020-01-01', max: '2020-12-31'});
      expect(screen.getByLabelText('Date')).toHaveAttribute('min', '2020-01-01');
    });

    it('reports a typed date', async () => {
      const {onDate} = setup({when: 'other'});
      await userEvent.type(screen.getByLabelText('Date'), '2020-03-05');
      expect(onDate).toHaveBeenCalled();
    });
  });
});
