import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import NurseryPlanter from './NurseryPlanter';

vi.mock('./SowSeedsModal', () => ({
  default: ({nursery}) => <div role="dialog" aria-label={`Sow in ${nursery.name}`} />,
}));

describe('NurseryPlanter', () => {
  it('starts closed', () => {
    render(<NurseryPlanter garden={{name: 'Nursery'}} gardens={[]} seeds={[]} label="Sow" />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens the sow seeds dialog for the nursery', async () => {
    render(<NurseryPlanter garden={{name: 'Nursery'}} gardens={[]} seeds={[]} label="Sow" />);
    await userEvent.click(screen.getByRole('button', {name: 'Sow'}));
    expect(screen.getByRole('dialog', {name: 'Sow in Nursery'})).toBeInTheDocument();
  });
});
