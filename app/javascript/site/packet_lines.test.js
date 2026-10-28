import { describe, expect, it } from 'vitest';
import { linesOf, mergeLines } from './packet_lines';

const line = (text, confidence, top, bottom = top + 20) => ({ text, confidence, top, bottom });

// What reading the cabbage packet at normal size, and at twice the size, gave
// (confidence, then the row it was on).
const NORMAL_SIZE = [
  line('yours', 48, 200),
  line('Danish Ballheaq', 91, 385),
  line('Brassica oleraceq', 77, 460),
  line('HEIRLOOM SEEDS', 79, 515),
  line('5 a Sat = 5 Nh bs oo', 27, 600),
  line('Packet Size: Home Garden', 88, 790),
  line('Contains APPRQY, 150 SEEDS', 61, 835),
  line('Code: 4341', 81, 890),
  line(') i', 68, 300),
];
const TWICE_SIZE = [
  line('Be : A»', 15, 0),
  line('Danish Ballheaq', 68, 387),
  line('Brassica oleraceq', 87, 462),
  line('HEIRLOOM SEEDS', 92, 517),
  line('Ee Be Fo Se Ribs oo or', 17, 600),
  line('pl po RE ot 4 NG AY * x, aR', 20, 640),
  line('Packet Size: Home Garden', 86, 792),
  line('Contains APPROX. 150 SEEDS', 77, 837),
  line(': Code; 4341 r', 27, 892),
];

describe('mergeLines', () => {
  const text = mergeLines([NORMAL_SIZE, TWICE_SIZE]);

  it('drops a line that is only marks, however sure it is', () => expect(text).not.toContain(') i'));
  it('drops the lines it is unsure of', () => expect(text).not.toMatch(/Ribs|Sat =|Be : A/));
  it('keeps the more confident reading of a line read twice', () => expect(text).toMatch(/Contains APPROX\. 150 SEEDS/));
  it('does not keep the less confident reading as well', () => expect(text).not.toMatch(/APPRQY/));
  it('keeps a line only the normal size read well', () => expect(text).toMatch(/Code: 4341/));
  it('reads top to bottom', () => {
    expect(text.split('\n')).toEqual([
      'Danish Ballheaq', 'Brassica oleraceq', 'HEIRLOOM SEEDS', 'Packet Size: Home Garden',
      'Contains APPROX. 150 SEEDS', 'Code: 4341',
    ]);
  });

  it('is empty when nothing was read with confidence', () => {
    expect(mergeLines([[line('xx', 10, 0)]])).toBe('');
  });

  it('keeps two lines that only touch', () => {
    expect(mergeLines([[line('one', 90, 0, 20), line('two', 90, 20, 40)]])).toBe('one\ntwo');
  });
});

describe('linesOf', () => {
  const result = { blocks: [{ paragraphs: [{ lines: [{ text: ' Code: 4341 \n', confidence: 81, bbox: { y0: 1780, y1: 1820 } }] }] }] };

  it('puts the row back on the photo, from the enlarged copy', () => {
    expect(linesOf(result, 2)).toEqual([{ text: 'Code: 4341', confidence: 81, top: 890, bottom: 910 }]);
  });

  it('has no lines when nothing was found', () => expect(linesOf({ blocks: null }, 2)).toEqual([]));
});
