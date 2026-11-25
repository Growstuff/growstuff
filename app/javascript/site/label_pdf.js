import {jsPDF} from 'jspdf';
import QRCode from 'qrcode';

export function labelLayout(width, height, modules) {
  if (![width, height].every((value) => Number.isFinite(value) && value >= 12 && value <= 300)) {
    throw new RangeError('Invalid label dimensions');
  }
  const stacked = height > width;
  if (Math.min(width, height) < 20) {
    // On tape-sized labels the QR's own quiet zone supplies the outer margin.
    // Use the entire short edge for the symbol, rather than shrinking modules.
    const qrSize = Math.min(width, height);
    if (qrSize / (modules + 8) < 0.3) throw new RangeError('QR code too small');
    return stacked ? {
      qrSize, qrX: 0, qrY: 0,
      textX: 0.5, textY: qrSize + 0.5, textWidth: width - 1, textHeight: height - qrSize - 1,
    } : {
      qrSize, qrX: 0, qrY: 0,
      textX: qrSize + 0.5, textY: 0.5, textWidth: width - qrSize - 1, textHeight: height - 1,
    };
  }
  // Keep just 1mm of outer padding and a 1mm text gap. Give the QR most of
  // the available space without reducing its required internal quiet zone.
  const qrSize = stacked ? Math.min(width - 2, (height - 3) * 0.7) : Math.min(height - 2, (width - 3) * 0.55);
  // Include the four-module quiet zone on every side. Tiny modules are hard
  // to resolve on inexpensive thermal printers, even with vector artwork.
  if (qrSize / (modules + 8) < 0.3) throw new RangeError('QR code too small');
  return stacked ? {
    qrSize, qrX: (width - qrSize) / 2, qrY: 1,
    textX: 1, textY: qrSize + 2, textWidth: width - 2, textHeight: height - qrSize - 3,
  } : {
    qrSize, qrX: 1, qrY: (height - qrSize) / 2,
    textX: qrSize + 2, textY: 1, textWidth: width - qrSize - 3, textHeight: height - 2,
  };
}

export function labelQRCode(width, height, url) {
  labelLayout(width, height, 0); // Validate dimensions before generating symbols.
  let fallback;
  for (const errorCorrectionLevel of ['H', 'Q', 'M', 'L']) {
    const qr = QRCode.create(url, {errorCorrectionLevel});
    let layout;
    try {
      layout = labelLayout(width, height, qr.modules.size);
    } catch (error) {
      if (!(error instanceof RangeError)) throw error;
      continue;
    }
    const candidate = {qr, layout};
    // Aim for roughly three dots per module on a 203dpi thermal printer.
    // More error correction is useful only if the denser symbol stays legible.
    if (layout.qrSize / (qr.modules.size + 8) >= 0.4) return candidate;
    // Keep the strongest correction that meets the existing 0.3mm minimum
    // when the label cannot accommodate the preferred module size.
    fallback ||= candidate;
  }
  if (fallback) return fallback;
  throw new RangeError('QR code too small');
}

// Rasterize only the text at 600dpi: browser font fallback preserves names in
// scripts the PDF's built-in fonts cannot encode. The QR itself stays vector.
function labelText(name, date, shortCode, width, height) {
  const scale = 600 / 25.4;
  const canvas = document.createElement('canvas');
  canvas.width = Math.ceil(width * scale);
  canvas.height = Math.ceil(height * scale);
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = 'white';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = 'black';
  ctx.textBaseline = 'top';
  // Prefer whole words; break an oversized word at grapheme boundaries so
  // names without spaces can still fit without splitting combining characters.
  const words = [...new Intl.Segmenter(undefined, {granularity: 'word'}).segment(name.replace(/\s/g, ' '))]
    .map((part) => part.segment);
  const graphemes = new Intl.Segmenter(undefined, {granularity: 'grapheme'});
  const compact = height < 14;
  for (let size = 14; size >= 6; size -= 0.5) {
    const pixels = size * 600 / 72;
    ctx.font = `${pixels}px sans-serif`;
    const lines = [''];
    for (const word of words) {
      const parts = ctx.measureText(word).width > canvas.width ?
        [...graphemes.segment(word)].map((part) => part.segment) : [word];
      for (const part of parts) {
        const last = lines.length - 1;
        if (ctx.measureText(lines[last] + part).width > canvas.width) lines.push(part.trimStart());
        else lines[last] += part;
      }
    }
    const lineHeight = pixels * 1.2;
    const codeSize = (compact ? 8 : 10) * 600 / 72;
    const dateSize = 8 * 600 / 72;
    ctx.font = `bold ${codeSize}px sans-serif`;
    if (ctx.measureText(shortCode).width > canvas.width) continue;
    ctx.font = `${dateSize}px sans-serif`;
    if (lines.length * lineHeight + (shortCode ? codeSize * 1.2 : 0) + (date ? dateSize * 1.5 : 0) > canvas.height ||
        ctx.measureText(date).width > canvas.width) continue;
    ctx.font = `${pixels}px sans-serif`;
    lines.forEach((line, index) => ctx.fillText(line, 0, index * lineHeight));
    ctx.font = `bold ${codeSize}px sans-serif`;
    if (shortCode) ctx.fillText(shortCode, 0, lines.length * lineHeight);
    ctx.font = `${dateSize}px sans-serif`;
    if (date) ctx.fillText(date, 0, canvas.height - dateSize * 1.3);
    return canvas;
  }
  throw new RangeError('Text does not fit');
}

export function createLabel({width, height, name, url, date, shortCode = ''}) {
  const {qr, layout} = labelQRCode(width, height, url);
  const {qrSize, qrX, qrY, textX, textY, textWidth, textHeight} = layout;
  const pdf = new jsPDF({
    unit: 'mm', format: [width, height],
    orientation: width > height ? 'landscape' : 'portrait',
    compress: true,
  });
  const cell = qrSize / (qr.modules.size + 8);
  pdf.setFillColor(0);
  for (let row = 0; row < qr.modules.size; row++) {
    for (let col = 0; col < qr.modules.size; col++) {
      if (qr.modules.get(row, col)) {
        pdf.rect(qrX + (col + 4) * cell, qrY + (row + 4) * cell, cell, cell, 'F');
      }
    }
  }
  pdf.addImage(labelText(name, date, shortCode, textWidth, textHeight).toDataURL('image/png'), 'PNG', textX, textY, textWidth, textHeight);
  pdf.setProperties({title: name, subject: url, creator: 'Growstuff'});
  return pdf;
}

export function createLabelImage({width, height, name, url, date, shortCode = ''}) {
  const {qr, layout} = labelQRCode(width, height, url);
  const {qrSize, qrX, qrY, textX, textY, textWidth, textHeight} = layout;
  const scale = 600 / 25.4;
  const canvas = document.createElement('canvas');
  canvas.width = Math.ceil(width * scale);
  canvas.height = Math.ceil(height * scale);
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = 'white';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = 'black';
  const cell = qrSize / (qr.modules.size + 8);
  // Round module boundaries to whole pixels so adjacent squares meet without
  // antialiased grey seams. Keep the same four-module quiet zone as the PDF.
  for (let row = 0; row < qr.modules.size; row++) {
    for (let col = 0; col < qr.modules.size; col++) {
      if (qr.modules.get(row, col)) {
        const x = Math.round((qrX + (col + 4) * cell) * scale);
        const y = Math.round((qrY + (row + 4) * cell) * scale);
        const right = Math.round((qrX + (col + 5) * cell) * scale);
        const bottom = Math.round((qrY + (row + 5) * cell) * scale);
        ctx.fillRect(x, y, right - x, bottom - y);
      }
    }
  }
  ctx.drawImage(labelText(name, date, shortCode, textWidth, textHeight),
    Math.round(textX * scale), Math.round(textY * scale));
  return canvas.toDataURL('image/png');
}
