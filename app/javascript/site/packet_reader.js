// The "Read the packet" button on a seed's form. Reads the photos of its packet
// in the browser, with Tesseract.js, and fills in the blanks of the form with
// what the packet says. It never changes a field that already has something in
// it, and nothing is saved until the member saves the form.
import { parsePacketText } from './packet_text';
import { cleanForOcr, loadPacketImage } from './packet_image';

// What parsePacketText finds, the seed attribute to put it in, and what to call it.
const FIELDS = {
  variety:         ['variety', 'variety'],
  batchNumber:     ['batch_number', 'batch number'],
  quantity:        ['quantity', 'quantity'],
  plantBeforeYear: ['plant_before_year', 'plant before year'],
  daysMin:         ['days_until_maturity_min', 'days to maturity'],
  daysMax:         ['days_until_maturity_max', null],
  rowSpacing:      ['row_spacing', 'row spacing'],
};

// Puts what was found in the form's blank fields. Returns the names of those it filled.
export function fillBlankFields(form, found) {
  const filled = [];
  Object.entries(FIELDS).forEach(([key, [attribute, name]]) => {
    const input = form.querySelector(`[name="seed[${attribute}]"]`);
    if (found[key] === undefined || !input || input.value.trim() !== '') return;
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
  const logger = ({ status, progress }) => {
    const message = progressMessage(status, progress, number, urls.length);
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
      const { data } = await worker.recognize(cleanForOcr(image));
      texts.push(data.text);
    }
    return texts.join('\n');
  } finally {
    await worker.terminate();
  }
}

// What to tell the member once it has read the packet: what it filled in, or
// why it did not.
export function resultMessage(found, filled) {
  if (filled.length) return `Filled in ${filled.join(', ')}. Check them against the packet before you save.`;
  if (Object.keys(found).length) return 'Found details on the packet, but those fields already have something in them, so nothing was changed.';
  return 'Could not find anything it knows how to read on this packet. Small, stamped or very decorative print is hard for it. What it did read is below.';
}

async function readPacket(button) {
  const reader = button.closest('[data-packet-reader]');
  const status = reader.querySelector('.packet-reader-status');
  const spinner = reader.querySelector('.packet-reader-spinner');
  const seen = reader.querySelector('.packet-reader-text');
  const { packetCrop: crop } = reader.dataset;
  button.disabled = true;
  spinner.classList.remove('d-none');
  try {
    const text = await readText(JSON.parse(reader.dataset.packetReader), (message) => {
      status.textContent = message;
    });
    const found = parsePacketText(text, { crop });
    const filled = fillBlankFields(button.closest('form'), found);
    status.textContent = resultMessage(found, filled);
    seen.querySelector('pre').textContent = text.trim() || '(no text)';
    seen.classList.remove('d-none');
  } catch (error) {
    status.textContent = 'Could not read the photos of the packet.';
  } finally {
    button.disabled = false;
    spinner.classList.add('d-none');
  }
}

document.addEventListener('click', (event) => {
  const button = event.target.closest('[data-packet-read]');
  if (button) readPacket(button);
});
