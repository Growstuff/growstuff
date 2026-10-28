import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, beforeAll, describe, expect, it, vi} from 'vitest';

import * as api from '../api';

import PostEditor from './PostEditor';

// The Flickr picker has its own tests. Here it just hands back the next photo.
let nextPhoto = 6;
vi.mock('./AddPhotoModal', () => ({
  default: ({onAdded}) => (
    <div role="dialog" aria-label="Add photo">
      <button type="button" onClick={() => {
        const id = nextPhoto++;
        onAdded({photo: {id, title: `Photo ${id}`, thumbnail_url: '/t.jpg', fullsize_url: '/f.jpg'}});
      }}>
        Add one
      </button>
    </div>
  ),
}));

const hidden = (container) => container.querySelector('input[type="hidden"]');

async function setup(props = {}) {
  const view = render(<PostEditor name="post[body]" {...props} />);
  await screen.findByRole('toolbar', {name: 'Formatting'});
  return view;
}

describe('PostEditor', () => {
  // jsdom has no layout, which ProseMirror asks for when it scrolls the cursor into view.
  beforeAll(() => {
    const rects = () => ({length: 0, item: () => null, [Symbol.iterator]: [][Symbol.iterator]});
    Range.prototype.getClientRects = rects;
    Range.prototype.getBoundingClientRect = () => ({top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0});
    Element.prototype.getClientRects = rects;
    document.elementFromPoint = () => null;
  });

  it('submits the markdown under the given name', async () => {
    const {container} = await setup({value: 'Hello **world**'});
    expect(hidden(container)).toHaveAttribute('name', 'post[body]');
  });

  it('starts with the markdown it was given', async () => {
    const {container} = await setup({value: 'Hello **world**'});
    expect(hidden(container)).toHaveValue('Hello **world**');
  });

  it('shows the markdown as formatted text', async () => {
    await setup({value: '## Pick from the plants'});
    expect(await screen.findByRole('heading', {level: 2, name: 'Pick from the plants'})).toBeInTheDocument();
  });

  it('starts empty without a value', async () => {
    const {container} = await setup();
    expect(hidden(container)).toHaveValue('');
  });

  it('opens on the Write tab', async () => {
    await setup();
    expect(screen.getByRole('tab', {name: 'Write'})).toHaveAttribute('aria-selected', 'true');
  });

  it('lists the formatting buttons', async () => {
    await setup();
    const names = screen.getAllByRole('button').map((b) => b.getAttribute('aria-label'));
    expect(names).toEqual(['Bold', 'Italic', 'Link', 'Bulleted list', 'Quote', 'Link to…']);
  });

  it('updates the markdown when a list is started', async () => {
    const {container} = await setup();
    await userEvent.click(screen.getByRole('button', {name: 'Bulleted list'}));
    await waitFor(() => expect(hidden(container).value).toMatch(/^-/));
  });

  it('marks the list button pressed inside a list', async () => {
    await setup({value: '- one'});
    expect(await screen.findByRole('button', {name: 'Bulleted list', pressed: true})).toBeInTheDocument();
  });

  it('turns a paragraph into a heading from the style menu', async () => {
    const {container} = await setup({value: 'Title'});
    await userEvent.selectOptions(screen.getByRole('combobox', {name: 'Text style'}), 'h2');
    await waitFor(() => expect(hidden(container)).toHaveValue('## Title'));
  });

  describe('Markdown tab', () => {
    it('shows the raw markdown', async () => {
      await setup({value: 'Hello **world**'});
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      expect(screen.getByRole('textbox', {name: 'Post body as markdown'})).toHaveValue('Hello **world**');
    });

    it('hides the formatting toolbar', async () => {
      await setup();
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      expect(screen.queryByRole('toolbar')).not.toBeInTheDocument();
    });

    it('updates the markdown as it is typed', async () => {
      const {container} = await setup();
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.type(screen.getByRole('textbox', {name: 'Post body as markdown'}), 'plain words');
      expect(hidden(container)).toHaveValue('plain words');
    });

    it('formats what was typed when going back to Write', async () => {
      await setup();
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.type(screen.getByRole('textbox', {name: 'Post body as markdown'}), '## Seeds');
      await userEvent.click(screen.getByRole('tab', {name: 'Write'}));
      expect(await screen.findByRole('heading', {level: 2, name: 'Seeds'})).toBeInTheDocument();
    });

    it('keeps the growstuff crop link syntax', async () => {
      const {container} = await setup({value: 'Grow [tomato](crop) here'});
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.click(screen.getByRole('tab', {name: 'Write'}));
      expect(hidden(container)).toHaveValue('Grow [tomato](crop) here');
    });
  });
  describe('Preview tab', () => {
    afterEach(() => vi.restoreAllMocks());

    it('is not offered without a preview address', async () => {
      await setup();
      expect(screen.queryByRole('tab', {name: 'Preview'})).not.toBeInTheDocument();
    });

    it('shows the body as the server renders it', async () => {
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ok: true, text: async () => '<p>Rendered <strong>body</strong></p>'}));
      await setup({value: 'Hello', previewUrl: '/posts/preview'});
      await userEvent.click(screen.getByRole('tab', {name: 'Preview'}));
      expect(await screen.findByText('body')).toBeInTheDocument();
      vi.unstubAllGlobals();
    });
  });

  describe('autosave', () => {
    afterEach(() => {
      vi.restoreAllMocks();
      vi.useRealTimers();
    });

    const autosave = {createUrl: '/posts', updateUrl: '/posts/a-draft', subjectId: 'post_subject'};

    async function typeBody(text) {
      const {container} = await setup({autosave});
      const input = document.createElement('input');
      input.id = 'post_subject';
      input.value = 'A title';
      document.body.appendChild(input);
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.type(screen.getByRole('textbox', {name: 'Post body as markdown'}), text);
      return {container, input};
    }

    it('saves the draft after typing stops', async () => {
      const patch = vi.spyOn(api, 'patchJson').mockResolvedValue({ok: true, status: 200, data: null});
      const {input} = await typeBody('words');
      await waitFor(() => expect(patch).toHaveBeenCalledWith(
        '/posts/a-draft', {post: {subject: 'A title', body: 'words', draft: true}}
      ), {timeout: 3000});
      input.remove();
    });

    it('says when the draft is saved', async () => {
      vi.spyOn(api, 'patchJson').mockResolvedValue({ok: true, status: 200, data: null});
      const {input} = await typeBody('words');
      expect(await screen.findByText(/Draft saved/, {}, {timeout: 3000})).toBeInTheDocument();
      input.remove();
    });

    it('says when saving fails', async () => {
      vi.spyOn(api, 'patchJson').mockResolvedValue({ok: false, status: 500, data: null});
      const {input} = await typeBody('words');
      expect(await screen.findByText(/Could not save the draft/, {}, {timeout: 3000})).toBeInTheDocument();
      input.remove();
    });

    it('saves a draft with text but no title yet', async () => {
      const patch = vi.spyOn(api, 'patchJson').mockResolvedValue({ok: true, status: 200, data: null});
      await setup({autosave});
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.type(screen.getByRole('textbox', {name: 'Post body as markdown'}), 'words');
      await waitFor(() => expect(patch).toHaveBeenCalledWith(
        '/posts/a-draft', {post: {subject: '', body: 'words', draft: true}}
      ), {timeout: 3000});
    });

    it('does not save when nothing is written', async () => {
      const patch = vi.spyOn(api, 'patchJson').mockResolvedValue({ok: true, status: 200, data: null});
      await setup({autosave});
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.click(screen.getByRole('tab', {name: 'Write'}));
      await new Promise((resolve) => setTimeout(resolve, 1800));
      expect(patch).not.toHaveBeenCalled();
    });
  });

  describe('links to crops, members and plantings', () => {
    const roundTrip = async (markdown) => {
      const {container} = await setup({value: markdown});
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.click(screen.getByRole('tab', {name: 'Write'}));
      return hidden(container);
    };

    it('shows a crop link as a chip', async () => {
      await setup({value: 'Grow [tomato](crop) here'});
      expect(await screen.findByText('@tomato')).toHaveClass('link-chip-crop');
    });

    it('shows a member link as a chip', async () => {
      await setup({value: 'Thanks [jane](member)'});
      expect(await screen.findByText('@jane')).toHaveClass('link-chip-member');
    });

    it('shows a planting link as a chip', async () => {
      await setup({value: 'See [my tomato](planting:jane-garden-tomato)'});
      expect(await screen.findByText('@my tomato')).toHaveClass('link-chip-planting');
    });

    it('keeps a member link as written', async () => {
      expect(await roundTrip('Thanks [jane](member)')).toHaveValue('Thanks [jane](member)');
    });

    it('keeps a planting link as written', async () => {
      expect(await roundTrip('See [my tomato](planting:jane-garden-tomato)')).toHaveValue(
        'See [my tomato](planting:jane-garden-tomato)'
      );
    });

    it('leaves ordinary links alone', async () => {
      expect(await roundTrip('A [link](http://example.com) here')).toHaveValue('A [link](http://example.com) here');
    });

    it('types an @ from the Link to button', async () => {
      const {container} = await setup();
      await userEvent.click(screen.getByRole('button', {name: 'Link to…'}));
      await waitFor(() => expect(hidden(container).value).toMatch(/@/));
    });
  });

  describe('photos in the text', () => {
    const photos = [{id: 5, title: 'Seed jar', thumbnail_url: '/t.jpg', fullsize_url: '/jar.jpg'}];
    const markdown = 'Before\n\n![Day two](photo:5/half)\n\nAfter';

    it('shows a photo with its caption', async () => {
      await setup({value: markdown, photos});
      expect(await screen.findByRole('img', {name: 'Day two'})).toHaveAttribute('src', '/jar.jpg');
    });

    it('marks the current size', async () => {
      await setup({value: markdown, photos});
      expect(await screen.findByRole('button', {name: 'Half', pressed: true})).toBeInTheDocument();
    });

    it('keeps the photo as written when switching tabs', async () => {
      const {container} = await setup({value: markdown, photos});
      await screen.findByRole('img', {name: 'Day two'});
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.click(screen.getByRole('tab', {name: 'Write'}));
      expect(hidden(container)).toHaveValue(markdown);
    });

    it('changes the size in the markdown', async () => {
      const {container} = await setup({value: markdown, photos});
      await userEvent.click(await screen.findByRole('button', {name: 'Side by side'}));
      await waitFor(() => expect(hidden(container).value).toContain('(photo:5/pair)'));
    });

    it('changes the caption in the markdown', async () => {
      const {container} = await setup({value: markdown, photos});
      const caption = await screen.findByLabelText('Caption');
      await userEvent.clear(caption);
      await userEvent.type(caption, 'Fresh');
      await waitFor(() => expect(hidden(container).value).toContain('![Fresh](photo:5/half)'));
    });

    it('removes the photo from the text', async () => {
      const {container} = await setup({value: markdown, photos});
      await userEvent.click(await screen.findByRole('button', {name: 'Remove'}));
      await waitFor(() => expect(hidden(container).value).not.toContain('photo:5'));
    });

    it('marks the card photo', async () => {
      await setup({value: markdown, photos, cardPhotoId: 5});
      expect(await screen.findByRole('button', {name: '★ Card photo', pressed: true})).toBeInTheDocument();
    });

    it('draws a placeholder for a photo it does not know', async () => {
      await setup({value: '![x](photo:99)'});
      expect(await screen.findByText('Photo 99')).toBeInTheDocument();
    });

    it('offers the Flickr photo button only to those who can add photos', async () => {
      await setup();
      expect(screen.queryByRole('button', {name: 'Flickr photo'})).not.toBeInTheDocument();
    });

    it('saves a blank new draft so a photo has a post to go on', async () => {
      const create = vi.spyOn(api, 'postJson').mockResolvedValue({ok: true, status: 201, data: {id: 12}});
      await setup({canAddPhoto: true, autosave: {createUrl: '/posts', updateUrl: null, subjectId: 'post_subject'}});
      await userEvent.click(screen.getByRole('button', {name: 'Flickr photo'}));
      await waitFor(() => expect(create).toHaveBeenCalledWith('/posts', {post: {subject: '', body: '', draft: true}}));
      create.mockRestore();
    });

    it('opens the picker once the draft is saved', async () => {
      vi.spyOn(api, 'postJson').mockResolvedValue({ok: true, status: 201, data: {id: 12}});
      await setup({canAddPhoto: true, autosave: {createUrl: '/posts', updateUrl: null, subjectId: 'post_subject'}});
      await userEvent.click(screen.getByRole('button', {name: 'Flickr photo'}));
      expect(await screen.findByRole('dialog')).toBeInTheDocument();
    });

    it('says so when the draft cannot be saved', async () => {
      vi.spyOn(api, 'postJson').mockResolvedValue({ok: false, status: 500, data: null});
      await setup({canAddPhoto: true, autosave: {createUrl: '/posts', updateUrl: null, subjectId: 'post_subject'}});
      await userEvent.click(screen.getByRole('button', {name: 'Flickr photo'}));
      expect(await screen.findByText(/could not be saved, so a photo cannot be added/)).toBeInTheDocument();
    });

    it('opens the Flickr picker for a post that exists', async () => {
      await setup({canAddPhoto: true, postPath: '/posts/a-post'});
      await userEvent.click(screen.getByRole('button', {name: 'Flickr photo'}));
      expect(await screen.findByRole('dialog')).toBeInTheDocument();
    });

    it('puts a picked photo in the text', async () => {
      const {container} = await setup({canAddPhoto: true, postPath: '/posts/a-post'});
      await userEvent.click(screen.getByRole('button', {name: 'Flickr photo'}));
      await userEvent.click(await screen.findByRole('button', {name: 'Add one'}));
      await waitFor(() => expect(hidden(container).value).toMatch(/\(photo:\d+\/wide\)/));
    });

    it('keeps the first photo when a second is picked while it is selected', async () => {
      const {container} = await setup({canAddPhoto: true, postPath: '/posts/a-post', value: 'Words'});
      for (let i = 0; i < 2; i += 1) {
        await userEvent.click(screen.getByRole('button', {name: 'Flickr photo'}));
        await userEvent.click(await screen.findByRole('button', {name: 'Add one'}));
        await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
        // Clicking a photo in the text selects it, as it is right after being placed.
        await userEvent.click(await screen.findByRole('img', {name: `Photo ${nextPhoto - 1}`}));
      }
      await waitFor(() => expect(hidden(container).value.match(/photo:\d+/g)).toHaveLength(2));
    });
  });
});
