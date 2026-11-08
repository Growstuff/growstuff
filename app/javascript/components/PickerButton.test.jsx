import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PickerButton from './PickerButton';

describe('PickerButton', () => {
  it('shows the label', () => {
    render(<PickerButton label="Add garden" onClick={vi.fn()} />);
    expect(screen.getByRole('button', {name: 'Add garden'})).toBeInTheDocument();
  });

  it('puts an icon before the label', () => {
    render(<PickerButton label="Change" icon="fas fa-pen" onClick={vi.fn()} />);
    expect(screen.getByRole('button', {name: 'Change'}).querySelector('i.fa-pen')).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const onClick = vi.fn();
    render(<PickerButton label="Add garden" onClick={onClick} />);
    await userEvent.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it('is not a submit button', () => {
    render(<PickerButton label="Add garden" onClick={vi.fn()} />);
    expect(screen.getByRole('button')).toHaveAttribute('type', 'button');
  });

  describe('with a sublabel', () => {
    it('bolds the label', () => {
      render(<PickerButton label="Plant" sublabel="something" onClick={vi.fn()} />);
      expect(screen.getByText('Plant').tagName).toBe('B');
    });

    it('shows the sublabel', () => {
      render(<PickerButton label="Plant" sublabel="something" onClick={vi.fn()} />);
      expect(screen.getByRole('button')).toHaveTextContent('Plantsomething');
    });
  });
});
