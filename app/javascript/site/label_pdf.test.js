import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';
import {PNG} from 'pngjs';
import QRCode from 'qrcode';
import {createLabel, labelLayout} from './label_pdf';

describe('labelLayout', () => {
  it.each([NaN, Infinity, 0, 19, 301])('rejects invalid width %s', (width) => {
    expect(() => labelLayout(width, 30, 29)).toThrow(RangeError);
  });

  it.each([NaN, Infinity, 0, 19, 301])('rejects invalid height %s', (height) => {
    expect(() => labelLayout(50, height, 29)).toThrow(RangeError);
  });

  it('rejects dimensions that make the QR modules too small', () => {
    expect(() => labelLayout(20, 20, 49)).toThrow(RangeError);
  });

  it('reserves space for text beside the QR code', () => {
    expect(labelLayout(50, 30, 29)).toMatchObject({qrSize: 22, textX: 26, textWidth: 22});
  });
});

describe('createLabel', () => {
  const options = {width: 50, height: 30, name: '菜園 🌱', url: 'https://www.growstuff.org/gardens/sunny-bed', date: '2026-11-07'};
  let context;

  beforeEach(() => {
    context = {
      fillRect: vi.fn(), fillText: vi.fn(),
      measureText: (text) => ({width: text.length * 20}),
    };
    const png = new PNG({width: 1, height: 1});
    png.data.fill(255);
    const image = 'data:image/png;base64,' + PNG.sync.write(png).toString('base64');
    vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue(context);
    vi.spyOn(HTMLCanvasElement.prototype, 'toDataURL').mockReturnValue(image);
  });

  afterEach(() => vi.restoreAllMocks());

  it.each([[50, 30], [30, 50], [50.5, 30.2], [40, 40]])('preserves the requested %s × %s mm page size', (width, height) => {
    const pdf = createLabel({...options, width, height});
    expect([pdf.internal.pageSize.getWidth(), pdf.internal.pageSize.getHeight()])
      .toEqual([expect.closeTo(width, 2), expect.closeTo(height, 2)]);
  });

  it('produces a PDF file', () => {
    expect(createLabel(options).output()).toMatch(/^%PDF-/);
  });

  it('keeps the label on a single page', () => {
    expect(createLabel(options).getNumberOfPages()).toBe(1);
  });

  it('renders the Unicode garden name without transliteration', () => {
    createLabel(options);
    expect(context.fillText).toHaveBeenCalledWith(options.name, 0, 0);
  });

  it('includes the print date', () => {
    createLabel(options);
    expect(context.fillText).toHaveBeenCalledWith(options.date, 0, expect.any(Number));
  });

  it('omits the date when none is supplied', () => {
    createLabel({...options, date: ''});
    expect(context.fillText).toHaveBeenCalledTimes(1);
  });

  it('encodes the planting URL when printing a planting', () => {
    const createQR = vi.spyOn(QRCode, 'create');
    const url = 'https://www.growstuff.org/plantings/basil';
    createLabel({...options, url, name: 'Basil', date: 'Planted 2026-03-10'});
    expect(createQR).toHaveBeenCalledWith(url, {errorCorrectionLevel: 'M'});
  });

  it('rejects names that cannot fit instead of clipping them', () => {
    expect(() => createLabel({...options, name: 'A'.repeat(10000)})).toThrow(RangeError);
  });
});
