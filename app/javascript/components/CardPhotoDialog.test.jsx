import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, describe, expect, it, vi} from 'vitest';

import * as api from '../api';
import CardPhotoDialog from './CardPhotoDialog';

const photos = [
  {id: 1, title: 'Fermenting jar', thumbnail_url: '/jar-thumb.jpg', fullsize_url: '/jar.jpg'},
  {id: 2, title: 'Drying on a plate', thumbnail_url: '/plate-thumb.jpg', fullsize_url: '/plate.jpg'},
];

const props = {url: '/posts/7', photos, subject: 'Saving tomato seed', excerpt: 'The tomatoes', byline: 'by brenda'};

async function openDialog(extra = {}) {
  const user = userEvent.setup();
  render(<CardPhotoDialog {...props} {...extra} />);
  await user.click(screen.getByRole('button', {name: 'Change'}));
  return user;
}

describe('CardPhotoDialog', () => {
  afterEach(() => vi.restoreAllMocks());

  it('is closed until Change is clicked', () => {
    render(<CardPhotoDialog {...props} />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('lists the photos in the post', async () => {
    await openDialog();
    expect(screen.getAllByRole('radio')).toHaveLength(2);
  });

  it('selects the current card photo', async () => {
    await openDialog({selectedId: 2});
    expect(screen.getByRole('radio', {name: /Drying on a plate/})).toBeChecked();
  });

  it('selects the first photo when none is chosen', async () => {
    await openDialog();
    expect(screen.getByRole('radio', {name: /Fermenting jar/})).toBeChecked();
  });

  it('previews the chosen photo', async () => {
    const user = await openDialog();
    await user.click(screen.getByRole('radio', {name: /Drying on a plate/}));
    expect(screen.getByAltText('Preview of the card photo')).toHaveAttribute('src', '/plate.jpg');
  });

  it('saves the chosen photo on the post', async () => {
    const patch = vi.spyOn(api, 'patchJson').mockResolvedValue({ok: false, status: 422, data: null});
    const user = await openDialog();
    await user.click(screen.getByRole('radio', {name: /Drying on a plate/}));
    await user.click(screen.getByRole('button', {name: 'Use this photo'}));
    await waitFor(() => expect(patch).toHaveBeenCalledWith('/posts/7', {post: {card_photo_id: 2}}));
  });

  it('shows an error when saving fails', async () => {
    vi.spyOn(api, 'patchJson').mockResolvedValue({ok: false, status: 422, data: null});
    const user = await openDialog();
    await user.click(screen.getByRole('button', {name: 'Use this photo'}));
    expect(await screen.findByRole('alert')).toHaveTextContent('could not be saved');
  });

  it('asks for a photo first when the post has none', async () => {
    await openDialog({photos: []});
    expect(screen.getByText(/Pick a photo from Flickr for this post first/)).toBeInTheDocument();
  });

  it('closes on Cancel', async () => {
    const user = await openDialog();
    await user.click(screen.getByRole('button', {name: 'Cancel'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
  it('says where the photos come from', async () => {
    await openDialog();
    expect(screen.getByText(/Photos come from your Flickr account/)).toBeInTheDocument();
  });

  it('links to the page photo dialog for another photo', async () => {
    await openDialog({addPhotoUrl: '/photos/new?id=7&type=post'});
    expect(screen.getByRole('link', {name: 'Pick a different photo from Flickr'})).toHaveAttribute('data-photo-dialog');
  });

  it('offers no other photo link without an address', async () => {
    await openDialog();
    expect(screen.queryByRole('link', {name: /Flickr/})).not.toBeInTheDocument();
  });
});
