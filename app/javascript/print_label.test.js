import {fireEvent, waitFor} from '@testing-library/dom';
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';
import {createLabel, createLabelImage} from './site/label_pdf';
import './print_label';

vi.mock('./site/label_pdf', () => ({createLabel: vi.fn(), createLabelImage: vi.fn()}));

describe('inline label preview', () => {
  let form;
  let preview;
  let save;

  beforeEach(() => {
    Object.defineProperty(document, 'fonts', {configurable: true, value: {ready: Promise.resolve()}});
    createLabelImage.mockReturnValue('data:image/png;base64,preview');
    save = vi.fn();
    createLabel.mockReturnValue({save});
    document.body.innerHTML = `
      <form data-print-label data-name="Basil" data-url="https://example.org/plantings/basil"
            data-date="Planted 2026-03-10" data-short-code="AB23" data-filename="label.pdf"
            data-error="Generation failed" data-size-error="Too small">
        <input name="width" value="50"><input name="height" value="30">
        <button type="submit">Download PDF</button>
        <p role="alert" hidden></p>
        <img data-label-preview alt="Label preview for Basil" hidden>
      </form>`;
    form = document.querySelector('form');
    preview = form.querySelector('img');
    document.dispatchEvent(new Event('DOMContentLoaded'));
  });

  afterEach(() => {
    document.body.innerHTML = '';
    delete document.fonts;
    vi.resetAllMocks();
  });

  it('shows a PNG preview on page load', async () => {
    await waitFor(() => expect(preview).toBeVisible());
  });

  it('passes the planting code to the preview renderer', async () => {
    await waitFor(() => expect(createLabelImage).toHaveBeenCalledWith(expect.objectContaining({shortCode: 'AB23'})));
  });

  it('updates the preview when dimensions change', async () => {
    form.elements.width.value = '60';
    fireEvent.change(form.elements.width);
    await waitFor(() => expect(createLabelImage).toHaveBeenLastCalledWith(expect.objectContaining({width: 60})));
  });

  it('hides a stale preview when dimensions are unreadable', async () => {
    await waitFor(() => expect(preview).toBeVisible());
    createLabelImage.mockImplementation(() => { throw new RangeError(); });
    fireEvent.change(form.elements.width);
    await waitFor(() => expect(preview).not.toBeVisible());
  });

  it('explains when dimensions are unreadable', async () => {
    createLabelImage.mockImplementation(() => { throw new RangeError(); });
    fireEvent.change(form.elements.width);
    await waitFor(() => expect(form.querySelector('[role="alert"]')).toHaveTextContent(form.dataset.sizeError));
  });

  it('keeps PDF downloads available', async () => {
    fireEvent.submit(form);
    await waitFor(() => expect(save).toHaveBeenCalledWith('label.pdf'));
  });
});
