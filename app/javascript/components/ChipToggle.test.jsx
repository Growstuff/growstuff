import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import ChipToggle from './ChipToggle';

const options = [{key: 'count', label: 'Count', href: '/h?by=count'}, {key: 'weight', label: 'Weight'}];

function setup(props = {}) {
  const onChange = vi.fn();
  render(<ChipToggle options={options} value="count" onChange={onChange} {...props} />);
  return onChange;
}

describe('ChipToggle', () => {
  it('shows a link for each option', () => {
    setup();
    expect(screen.getAllByRole('link')).toHaveLength(2);
  });

  it('marks the chosen option', () => {
    setup();
    expect(screen.getByText('Count')).toHaveAttribute('aria-pressed', 'true');
  });

  it('does not mark the others', () => {
    setup();
    expect(screen.getByText('Weight')).toHaveAttribute('aria-pressed', 'false');
  });

  it('keeps the href for use without JavaScript', () => {
    setup();
    expect(screen.getByText('Count')).toHaveAttribute('href', '/h?by=count');
  });

  it('falls back to # without an href', () => {
    setup();
    expect(screen.getByText('Weight')).toHaveAttribute('href', '#');
  });

  it('reports the key of the clicked option', async () => {
    const onChange = setup();
    await userEvent.click(screen.getByText('Weight'));
    expect(onChange).toHaveBeenCalledWith('weight');
  });

  it('adds the given class to the group', () => {
    setup({className: 'extra'});
    expect(screen.getByRole('group')).toHaveClass('home-chips', 'extra');
  });
});
