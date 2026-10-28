import { describe, expect, it } from 'vitest';
import { parsePacketText } from './packet_text';

// What Tesseract.js made of two real packets, after packet_image.js had cleaned
// them up: the mistakes are its own ("Augisi", "dizgonal", the stray bars).
const BARLEY = `
"Koanea Gardens
| BARLEY
Karan - 163 |
0S He ‘itane ; (Huruevm vulgare)
Descri tic: 115-120 days to maturity, dwaif stature,
16% keine! protein, successful under limited irrigation
Sowiny: Sow either late Autumn or early Spring,
| Approx: 120, enough to plant 1 M? of bio intensive bed at
10cm dizgonal spacing's.
Batch number; HOVG0022 :
| Sow by: Augisi 2026
Organically grown in RZ, especially for home gardens,
`;

const TOMATO = `
= Island Bay Italian
NZ Heritage (Lycopersicon lycopersicum)
Description: Indeterminate. An outstanding, large, even
10cm deep pots or trays to 10cm diagonal spacings. When
10-15¢cm high transplant into garden 50cm spacings in rows.
| Two rows per 1m wide bed. Needs staking.
| Approx 15 seeds per packet
Batch number: LYIG0403
| Sow by: December 2026 i
`;

describe('parsePacketText', () => {
  describe('with a barley packet', () => {
    const found = parsePacketText(BARLEY, { crop: 'Barley' });

    it('finds the variety, not the crop', () => expect(found.variety).toBe('Karan - 163'));
    it('finds the seed count', () => expect(found.quantity).toBe(120));
    it('finds the year to sow by, through a garbled month', () => expect(found.plantBeforeYear).toBe(2026));
    it('finds the shortest time to maturity', () => expect(found.daysMin).toBe(115));
    it('finds the longest time to maturity', () => expect(found.daysMax).toBe(120));
    it('finds the batch number', () => expect(found.batchNumber).toBe('HOVG0022'));
    it('does not take diagonal spacing for row spacing', () => expect(found.rowSpacing).toBeUndefined());
  });

  describe('with a tomato packet', () => {
    const found = parsePacketText(TOMATO, { crop: 'Tomato' });

    it('finds the variety', () => expect(found.variety).toBe('Island Bay Italian'));
    it('finds the seed count', () => expect(found.quantity).toBe(15));
    it('finds the year to sow by', () => expect(found.plantBeforeYear).toBe(2026));
    it('finds the row spacing', () => expect(found.rowSpacing).toBe(50));
    it('finds the batch number', () => expect(found.batchNumber).toBe('LYIG0403'));
    it('has no days to maturity, as the packet says none', () => expect(found.daysMin).toBeUndefined());
  });

  describe('with a single time to maturity', () => {
    it('uses it for both ends', () => {
      expect(parsePacketText('Matures in 65 days to maturity')).toMatchObject({ daysMin: 65, daysMax: 65 });
    });
  });

  describe('with a year written as packed for', () => {
    it('finds the year', () => expect(parsePacketText('Packed for 2027').plantBeforeYear).toBe(2027));
  });

  describe('with a seed count in thousands', () => {
    it('reads past the comma', () => expect(parsePacketText('Approx 1,200 seeds').quantity).toBe(1200));
  });

  describe('with a batch number with no digits in it', () => {
    it('does not take a word for one', () => expect(parsePacketText('Batch number unknown').batchNumber).toBeUndefined());
  });

  describe('with a line above the Latin name that is only the crop', () => {
    it('does not call the crop the variety', () => {
      expect(parsePacketText('TOMATO\n(Lycopersicon lycopersicum)', { crop: 'Tomato' }).variety).toBeUndefined();
    });
  });

  describe('with nothing on it', () => {
    it('finds nothing', () => expect(parsePacketText('')).toEqual({}));
  });
});
