import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, beforeAll, describe, expect, it, vi} from 'vitest';

import * as api from '../api';

import PostEditor from './PostEditor';

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

    it('does not save without a title', async () => {
      const patch = vi.spyOn(api, 'patchJson').mockResolvedValue({ok: true, status: 200, data: null});
      await setup({autosave});
      await userEvent.click(screen.getByRole('tab', {name: 'Markdown'}));
      await userEvent.type(screen.getByRole('textbox', {name: 'Post body as markdown'}), 'words');
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
});
