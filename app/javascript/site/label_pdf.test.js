import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';
import {PNG} from 'pngjs';
import QRCode from 'qrcode';
import {createLabel, createLabelImage, labelLayout, labelQRCode} from './label_pdf';

describe('labelLayout', () => {
  it.each([NaN, Infinity, 0, 11.9, 301])('rejects invalid width %s', (width) => {
    expect(() => labelLayout(width, 30, 29)).toThrow(RangeError);
  });

  it.each([NaN, Infinity, 0, 11.9, 301])('rejects invalid height %s', (height) => {
    expect(() => labelLayout(50, height, 29)).toThrow(RangeError);
  });

  it('rejects dimensions that make the QR modules too small', () => {
    expect(() => labelLayout(20, 20, 49)).toThrow(RangeError);
  });

  it('reserves space for text beside the QR code', () => {
    expect(labelLayout(50, 30, 29)).toMatchObject({qrSize: 25.85, textX: 27.85, textWidth: 21.15});
  });

  it('uses one millimetre of outer padding on landscape labels', () => {
    expect(labelLayout(50, 30, 29)).toMatchObject({qrX: 1, textY: 1, textHeight: 28});
  });

  it('enlarges the QR code on portrait labels', () => {
    expect(labelLayout(30, 50, 29)).toMatchObject({qrSize: 28, qrX: 1, qrY: 1, textY: 30});
  });

  it('uses the full tape height for the QR code on a 40 × 12 mm label', () => {
    expect(labelLayout(40, 12, 29)).toMatchObject({qrSize: 12, qrX: 0, qrY: 0, textX: 12.5, textWidth: 27, textHeight: 11});
  });
});

describe('labelQRCode', () => {
  const url = 'https://www.growstuff.org/plantings/basil';

  it('uses high error correction when there is room', () => {
    expect(labelQRCode(50, 30, url).qr.errorCorrectionLevel).toEqual(QRCode.create(url, {errorCorrectionLevel: 'H'}).errorCorrectionLevel);
  });

  it('favours readable modules over denser error correction on smaller labels', () => {
    const {qr, layout} = labelQRCode(40, 30, url);
    expect(layout.qrSize / (qr.modules.size + 8)).toBeGreaterThanOrEqual(0.4);
  });

  it('reduces error correction when a tiny label needs a simpler symbol', () => {
    expect(labelQRCode(30, 20, url).qr.errorCorrectionLevel).toEqual(QRCode.create(url, {errorCorrectionLevel: 'M'}).errorCorrectionLevel);
  });

  it('keeps at least 0.3mm per module including the quiet zone', () => {
    const {qr, layout} = labelQRCode(30, 20, url);
    expect(layout.qrSize / (qr.modules.size + 8)).toBeGreaterThanOrEqual(0.3);
  });

  it('keeps a readable QR code on a 40 × 12 mm label', () => {
    const {qr, layout} = labelQRCode(40, 12, url);
    expect(layout.qrSize / (qr.modules.size + 8)).toBeGreaterThanOrEqual(0.3);
  });

  it('rejects a URL too dense for a 40 × 12 mm label', () => {
    expect(() => labelQRCode(40, 12, `${url}/${'a'.repeat(100)}`)).toThrow(RangeError);
  });

  it('rejects labels that cannot fit a readable QR code', () => {
    expect(() => labelQRCode(20, 20, url)).toThrow(RangeError);
  });

  it('preserves the complete destination URL', () => {
    const {qr} = labelQRCode(50, 30, url);
    expect(qr.segments.map((segment) => new TextDecoder().decode(segment.data)).join('')).toBe(url);
  });
});

describe('createLabel', () => {
  const options = {width: 50, height: 30, name: '菜園 🌱', url: 'https://www.growstuff.org/gardens/sunny-bed', date: '2026-11-07'};
  let context;

  beforeEach(() => {
    context = {
      fillRect: vi.fn(), fillText: vi.fn(), drawImage: vi.fn(),
      measureText: (text) => ({width: text.length * 20}),
    };
    const png = new PNG({width: 1, height: 1});
    png.data.fill(255);
    const image = 'data:image/png;base64,' + PNG.sync.write(png).toString('base64');
    vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue(context);
    vi.spyOn(HTMLCanvasElement.prototype, 'toDataURL').mockReturnValue(image);
  });

  afterEach(() => vi.restoreAllMocks());

  it.each([[50, 30], [30, 50], [50.5, 30.2], [40, 40], [40, 12]])('preserves the requested %s × %s mm page size', (width, height) => {
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

  it.each([[50, 30], [30, 50], [40, 40]])('renders the planting code on a %s × %s mm label', (width, height) => {
    createLabel({...options, width, height, shortCode: 'AB23'});
    expect(context.fillText).toHaveBeenCalledWith('AB23', 0, expect.any(Number));
  });

  it('keeps the planting code between the name and date', () => {
    createLabel({...options, shortCode: 'AB23'});
    expect(context.fillText.mock.calls.map(([text]) => text)).toEqual([options.name, 'AB23', options.date]);
  });

  it('omits the planting code when none is supplied', () => {
    createLabel(options);
    expect(context.fillText).toHaveBeenCalledTimes(2);
  });

  it.each([createLabel, createLabelImage])('fits the planting name, code and date on compact labels with %s', (render) => {
    render({...options, width: 40, height: 12, name: 'Basil', shortCode: 'AB23', date: 'Planted 2026-03-10'});
    expect(context.fillText.mock.calls.map(([text]) => text)).toEqual(['Basil', 'AB23', 'Planted 2026-03-10']);
  });

  describe('compact label typography', () => {
    let drawn;

    beforeEach(() => {
      drawn = [];
      context.fillText.mockImplementation(function(text, x, y) {
        drawn.push({text, y, font: this.font});
      });
      createLabelImage({...options, width: 40, height: 12, name: 'Basil', shortCode: 'AB23', date: 'Planted 2026-03-10'});
    });

    it('keeps an eight-point name alongside the larger date', () => {
      expect(parseFloat(drawn[0].font)).toBeGreaterThanOrEqual(8 * 600 / 72);
    });

    it('uses an eight-point planting code', () => {
      expect(drawn[1].font).toBe(`bold ${8 * 600 / 72}px sans-serif`);
    });

    it('uses an eight-point date', () => {
      expect(drawn[2].font).toBe(`${8 * 600 / 72}px sans-serif`);
    });

    it('keeps the code clear of the date', () => {
      expect(drawn[1].y + 8 * 600 / 72 * 1.2).toBeLessThanOrEqual(drawn[2].y);
    });
  });

  it('encodes the planting URL when printing a planting', () => {
    const createQR = vi.spyOn(QRCode, 'create');
    const url = 'https://www.growstuff.org/plantings/basil';
    createLabel({...options, url, name: 'Basil', date: 'Planted 2026-03-10'});
    expect(createQR).toHaveBeenCalledWith(url, {errorCorrectionLevel: 'H'});
  });

  it('rejects names that cannot fit instead of clipping them', () => {
    expect(() => createLabel({...options, name: 'A'.repeat(10000)})).toThrow(RangeError);
  });

  describe('PNG rendering', () => {
    it('produces a lossless PNG data URL', () => {
      expect(createLabelImage(options)).toMatch(/^data:image\/png;base64,/);
    });

    it.each([[50, 30], [30, 50], [50.5, 30.2], [40, 12]])('renders a %s × %s mm label at 600dpi', (width, height) => {
      createLabelImage({...options, width, height});
      const canvas = HTMLCanvasElement.prototype.toDataURL.mock.instances[0];
      expect([canvas.width, canvas.height]).toEqual([Math.ceil(width * 600 / 25.4), Math.ceil(height * 600 / 25.4)]);
    });

    it('includes the planting code', () => {
      createLabelImage({...options, shortCode: 'AB23'});
      expect(context.fillText).toHaveBeenCalledWith('AB23', 0, expect.any(Number));
    });

    it('keeps QR module boundaries on whole pixels', () => {
      createLabelImage(options);
      expect(context.fillRect.mock.calls.every((rectangle) => rectangle.every(Number.isInteger))).toBe(true);
    });

    it('uses the same QR symbol as the PDF', () => {
      const createQR = vi.spyOn(QRCode, 'create');
      createLabel(options);
      const pdfCalls = [...createQR.mock.calls];
      createQR.mockClear();
      createLabelImage(options);
      expect(createQR.mock.calls).toEqual(pdfCalls);
    });

    it('rejects unreadable dimensions', () => {
      expect(() => createLabelImage({...options, width: 20, height: 20})).toThrow(RangeError);
    });
  });
});
