import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PhotoPicker from './PhotoPicker';

vi.mock('./AddPhotoModal', () => ({
  default: ({label, newUrl}) => <div role="dialog" aria-label={label} data-url={newUrl} />,
}));

function setup() {
  render(<PhotoPicker label="Add photo" sublabel="to a garden" garden={{name: 'Back yard'}} newUrl="/photos/new?type=garden&id=1" />);
}

describe('PhotoPicker', () => {
  it('shows the button with its sublabel', () => {
    setup();
    expect(screen.getByRole('button')).toHaveTextContent('Add phototo a garden');
  });

  it('starts closed', () => {
    setup();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens the dialog named for the garden', async () => {
    setup();
    await userEvent.click(screen.getByRole('button'));
    expect(screen.getByRole('dialog', {name: 'Back yard'})).toBeInTheDocument();
  });

  it('gives the dialog the new photo url', async () => {
    setup();
    await userEvent.click(screen.getByRole('button'));
    expect(screen.getByRole('dialog')).toHaveAttribute('data-url', '/photos/new?type=garden&id=1');
  });
});
