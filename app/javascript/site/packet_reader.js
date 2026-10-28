// The "Read the packet" button on a seed's form. Reads the photos of its packet
// in the browser, with Tesseract.js, and fills in the blanks of the form with
// what the packet says. It never changes a field that already has something in
// it, and nothing is saved until the member saves the form.
import { parsePacketText } from './packet_text';
import { cleanForOcr, loadPacketImage } from './packet_image';
import { linesOf, mergeLines } from './packet_lines';

// Each photo is read at these sizes: big lettering reads best at the first, small print at the second.
const SCALES = [1, 2];

// What parsePacketText finds, the seed attribute to put it in, and what to call it.
const FIELDS = {
  variety:         ['variety', 'variety'],
  batchNumber:     ['batch_number', 'batch number'],
  quantity:        ['quantity', 'quantity'],
  plantBeforeYear: ['plant_before_year', 'plant before year'],
  daysMin:         ['days_until_maturity_min', 'days to maturity'],
  daysMax:         ['days_until_maturity_max', null],
  rowSpacing:      ['row_spacing', 'row spacing'],
  heirloom:        ['heirloom', 'heirloom'],
  organic:         ['organic', 'organic'],
};

// A choice left at "unknown" has not been answered, so the packet may answer it.
function isBlank(input) {
  const value = input.value.trim();
  return value === '' || (input.tagName === 'SELECT' && value === 'unknown');
}

// Puts what was found in the form's blank fields. Returns the names of those it filled.
export function fillBlankFields(form, found) {
  const filled = [];
  Object.entries(FIELDS).forEach(([key, [attribute, name]]) => {
    const input = form.querySelector(`[name="seed[${attribute}]"]`);
    if (found[key] === undefined || !input || !isBlank(input)) return;
    input.value = found[key];
    input.classList.add('packet-reader-filled');
    input.dispatchEvent(new Event('input', { bubbles: true }));
    if (name) filled.push(name);
  });
  return filled;
}

// What to tell the member Tesseract.js is doing, from what it reports: loading
// its engine and the English data (the slow part, but only the first time, as
// the browser keeps them), then reading, with how far through it is.
export function progressMessage(status, progress, number, count) {
  if (status === 'recognizing text') {
    const photo = count > 1 ? `photo ${number} of ${count}` : 'the photo';
    return `Reading ${photo}: ${Math.round(progress * 100)}%`;
  }
  if (status.startsWith('loading')) return 'Loading the reader. This is only slow the first time.';
  return null;
}

async function readText(urls, report) {
  let number = 0;
  let pass = 0;
  const logger = ({ status, progress }) => {
    const message = progressMessage(status, (pass + progress) / SCALES.length, number, urls.length);
    if (message) report(message);
  };
  report('Loading the reader. This is only slow the first time.');
  const { createWorker } = await import('tesseract.js');
  const worker = await createWorker('eng', 1, { logger });
  try {
    const texts = [];
    for (const url of urls) {
      number += 1;
      report(`Fetching photo ${number} of ${urls.length}`);
      const image = await loadPacketImage(url);
      const readings = [];
      for (const [index, scale] of SCALES.entries()) {
        pass = index;
        const { data } = await worker.recognize(cleanForOcr(image, { scale }), {}, { blocks: true });
        readings.push(linesOf(data, scale));
      }
      texts.push(mergeLines(readings));
    }
    return texts.join('\n');
  } finally {
    await worker.terminate();
  }
}

// Puts the text read from the packet in the form's "Text from the packet" box,
// where the member can see it and correct it. Unlike the other fields it
// replaces what is there: it is the record of the latest reading.
export function fillPacketText(form, text) {
  const box = form.querySelector('[name="seed[packet_text]"]');
  const cleaned = text.trim();
  if (!box || !cleaned) return false;
  box.value = cleaned;
  box.classList.add('packet-reader-filled');
  box.dispatchEvent(new Event('input', { bubbles: true }));
  return true;
}

// What to tell the member once it has read the packet: what it filled in, or
// why it did not, and where the text it read went.
export function resultMessage(found, filled, textSaved = false) {
  const where = textSaved ? ' The text it read is in the "Text from the packet" box below.' : '';
  if (filled.length) return `Filled in ${filled.join(', ')}. Check them against the packet before you save.${where}`;
  if (Object.keys(found).length) return `Found details on the packet, but those fields already have something in them, so nothing was changed.${where}`;
  if (textSaved) return `Could not pick out any details. Small, stamped or very decorative print is hard to read.${where}`;
  return 'Could not read any text on the photos of the packet.';
}

async function readPacket(button) {
  const reader = button.closest('[data-packet-reader]');
  const status = reader.querySelector('.packet-reader-status');
  const spinner = reader.querySelector('.packet-reader-spinner');
  const { packetCrop: crop } = reader.dataset;
  const scientificNames = JSON.parse(reader.dataset.packetScientific || '[]');
  button.disabled = true;
  spinner?.classList.remove('d-none');
  try {
    const text = await readText(JSON.parse(reader.dataset.packetReader), (message) => {
      status.textContent = message;
    });
    const form = button.closest('form');
    const found = parsePacketText(text, { crop, scientificNames });
    const filled = fillBlankFields(form, found);
    status.textContent = resultMessage(found, filled, fillPacketText(form, text));
  } catch (error) {
    status.textContent = 'Could not read the photos of the packet.';
  } finally {
    button.disabled = false;
    spinner?.classList.add('d-none');
  }
}

document.addEventListener('click', (event) => {
  const button = event.target.closest('[data-packet-read]');
  if (button) readPacket(button);
});
