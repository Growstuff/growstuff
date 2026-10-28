// What a seed packet prints, read out of the text OCR made of its photo. OCR
// garbles words, so each of these is forgiving of the text around a number,
// and leaves out what it is not sure of rather than guess.

const YEAR = '((?:19|20)\\d\\d)';

function firstMatch(text, patterns) {
  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) return match;
  }
  return null;
}

// The line that holds the Latin name: one in brackets, or one that starts with
// the genus of a scientific name the crop is known by (OCR garbles the rest).
function latinNameLine(lines, scientificNames) {
  const bracketed = lines.findIndex((line) => /\(\s*[A-Z][a-z]+\s+[a-z]+\s*\)/.test(line));
  if (bracketed !== -1) return bracketed;
  const genera = scientificNames.map((name) => name.trim().split(/\s+/)[0].toLowerCase()).filter((genus) => genus.length >= 4);
  return lines.findIndex((line, i) => i > 0 && genera.some((genus) => line.toLowerCase().replace(/^\W+/, '').startsWith(genus.slice(0, 5))));
}

// The line above the Latin name, which is where packets put the variety:
//   TOMATO
//   Island Bay Italian
//   NZ Heritage            (Lycopersicon lycopersicum)
function variety(text, crop, scientificNames) {
  const lines = text.split('\n').map((line) => line.trim()).filter(Boolean);
  const latin = latinNameLine(lines, scientificNames);
  if (latin < 1) return null;
  for (let i = latin - 1; i >= Math.max(latin - 2, 0); i--) {
    const name = lines[i].replace(/^[^A-Za-z0-9]+|[^A-Za-z0-9]+$/g, '');
    if (name.length < 3 || name.length > 60 || (name.match(/[A-Za-z]/g) || []).length < 3) continue;
    if (crop && name.toLowerCase() === crop.toLowerCase()) continue;
    return name;
  }
  return null;
}

// Returns only the facts found, named as the seed's own attributes:
// quantity, plantBeforeYear, daysMin, daysMax, rowSpacing, batchNumber, variety,
// heirloom, organic. `crop` is the crop's name, and `scientificNames` the Latin
// names it goes by, to find the variety by.
export function parsePacketText(text, { crop, scientificNames = [] } = {}) {
  const found = {};

  const quantity = firstMatch(text, [/approx\.?:?\s*(\d[\d,]*)/i, /(\d[\d,]*)\s+seeds?\b/i]);
  if (quantity) found.quantity = Number(quantity[1].replace(/,/g, ''));

  const year = firstMatch(text, [
    new RegExp(`(?:sow|plant|use|best)\\s*(?:by|before)\\W*(?:[A-Za-z]+\\W+)?${YEAR}`, 'i'),
    new RegExp(`packed\\s+for\\W*(?:[A-Za-z]+\\W+)?${YEAR}`, 'i'),
  ]);
  if (year) found.plantBeforeYear = Number(year[1]);

  const range = text.match(/(\d{2,3})\s*(?:-|–|to)\s*(\d{2,3})\s*days/i);
  const single = firstMatch(text, [
    /(\d{2,3})\s*days\s*(?:to|until)\s*(?:maturity|harvest)/i,
    /maturity\W{0,3}(\d{2,3})\s*days/i,
  ]);
  if (range && Number(range[1]) <= Number(range[2])) {
    found.daysMin = Number(range[1]);
    found.daysMax = Number(range[2]);
  } else if (single) {
    found.daysMin = found.daysMax = Number(single[1]);
  }

  const spacing = firstMatch(text, [
    /(\d{2,3})\s*cm\s*(?:spacings?\s+)?(?:in|between)\s+rows/i,
    /rows?\s*(?:are\s*)?(\d{2,3})\s*cm\s*apart/i,
    /row\s*spacing\W*(\d{2,3})\s*cm/i,
  ]);
  if (spacing) found.rowSpacing = Number(spacing[1]);

  const batch = text.match(/batch\s*(?:number|no\.?|#)?\W*((?=[A-Z0-9]*\d)[A-Z0-9]{4,})/i);
  if (batch) found.batchNumber = batch[1];

  const name = variety(text, crop, scientificNames);
  if (name) found.variety = name;

  if (/heirloom/i.test(text)) found.heirloom = 'heirloom';

  const organic = text.match(/(non[-\s]?)?certified\s+organic/i);
  if (organic && !organic[1]) found.organic = 'certified organic';

  return found;
}
