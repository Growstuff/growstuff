import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import PhotoDialog from './PhotoDialog';

vi.mock('./AddPhotoModal', () => ({
  default: ({label, newUrl, onClose}) => (
    <div role="dialog" aria-label={label} data-url={newUrl}>
      <button type="button" onClick={onClose}>Close</button>
    </div>
  ),
}));

function setup() {
  render(
      <>
        <a href="/photos/new?type=planting&id=5" data-photo-dialog data-photo-label="Tomato planting">Add photo</a>
        <a href="/photos/new?type=garden&id=2" data-photo-dialog>Add garden photo</a>
        <a href="/about">About</a>
        <PhotoDialog label="Fallback" />
      </>,
  );
}

describe('PhotoDialog', () => {
  it('draws nothing to start with', () => {
    setup();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('opens from an add photo link', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Add photo'}));
    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });

  it('names the record from the link', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Add photo'}));
    expect(screen.getByRole('dialog', {name: 'Tomato planting'})).toBeInTheDocument();
  });

  it('works from the link\'s own href', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Add photo'}));
    expect(screen.getByRole('dialog')).toHaveAttribute('data-url', '/photos/new?type=planting&id=5');
  });

  it('falls back to its own label', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Add garden photo'}));
    expect(screen.getByRole('dialog', {name: 'Fallback'})).toBeInTheDocument();
  });

  it('ignores other links', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'About'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('closes', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Add photo'}));
    await userEvent.click(screen.getByRole('button', {name: 'Close'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
