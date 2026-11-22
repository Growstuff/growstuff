import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import FirstStepsPlanter from './FirstStepsPlanter';

vi.mock('./SowSeedsModal', () => ({
  default: ({nursery, gardens}) => <div role="dialog" aria-label={`Sow into ${nursery === null ? 'a garden' : 'the nursery'} of ${gardens.length}`} />,
}));

const gardens = [{id: 10, name: 'Garden', slug: 'garden'}];

describe('FirstStepsPlanter', () => {
  it('starts closed', () => {
    render(<FirstStepsPlanter gardens={gardens} seeds={[]} label="Record a planting in my garden" />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens the sow seeds dialog with no nursery', async () => {
    render(<FirstStepsPlanter gardens={gardens} seeds={[]} label="Record a planting in my garden" />);
    await userEvent.click(screen.getByRole('button', {name: 'Record a planting in my garden'}));
    expect(screen.getByRole('dialog', {name: 'Sow into a garden of 1'})).toBeInTheDocument();
  });
});
