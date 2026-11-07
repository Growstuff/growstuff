import { describe, it, expect, beforeEach, vi } from 'vitest';
import { copyText } from './copy_credit';

describe('copyText', () => {
  let button;
  const clipboard = { writeText: vi.fn(() => Promise.resolve()) };

  beforeEach(() => {
    document.body.innerHTML = '<button data-copy-text="Photo by shiny" data-copied="Copied">Copy credit</button>';
    button = document.querySelector('button');
  });

  it('copies the text', async () => {
    await copyText(button, clipboard);
    expect(clipboard.writeText).toHaveBeenCalledWith('Photo by shiny');
  });

  it('says it copied', async () => {
    await copyText(button, clipboard);
    expect(button.textContent).toBe('Copied');
  });
});
