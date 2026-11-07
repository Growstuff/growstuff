import {jsPDF} from 'jspdf';
import QRCode from 'qrcode';

export function labelLayout(width, height, modules) {
  if (![width, height].every((value) => Number.isFinite(value) && value >= 20 && value <= 300)) {
    throw new RangeError('Invalid label dimensions');
  }
  const stacked = height > width;
  const qrSize = stacked ? Math.min(width - 4, (height - 6) * 0.6) : Math.min(height - 4, (width - 6) / 2);
  // Include the four-module quiet zone on every side. Tiny modules are hard
  // to resolve on inexpensive thermal printers, even with vector artwork.
  if (qrSize / (modules + 8) < 0.3) throw new RangeError('QR code too small');
  return stacked ? {
    qrSize, qrX: (width - qrSize) / 2, qrY: 2,
    textX: 2, textY: qrSize + 4, textWidth: width - 4, textHeight: height - qrSize - 6,
  } : {
    qrSize, qrX: 2, qrY: (height - qrSize) / 2,
    textX: qrSize + 4, textY: 2, textWidth: width - qrSize - 6, textHeight: height - 4,
  };
}

// Rasterize only the text at 600dpi: browser font fallback preserves names in
// scripts the PDF's built-in fonts cannot encode. The QR itself stays vector.
function labelText(name, date, width, height) {
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
  for (let size = 12; size >= 6; size -= 0.5) {
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
    const dateSize = 6 * 600 / 72;
    ctx.font = `${dateSize}px sans-serif`;
    if (lines.length * lineHeight + (date ? dateSize * 2 : 0) > canvas.height ||
        ctx.measureText(date).width > canvas.width) continue;
    ctx.font = `${pixels}px sans-serif`;
    lines.forEach((line, index) => ctx.fillText(line, 0, index * lineHeight));
    ctx.font = `${dateSize}px sans-serif`;
    if (date) ctx.fillText(date, 0, canvas.height - dateSize * 1.3);
    return canvas.toDataURL('image/png');
  }
  throw new RangeError('Text does not fit');
}

export function createLabel({width, height, name, url, date}) {
  const qr = QRCode.create(url, {errorCorrectionLevel: 'M'});
  const {qrSize, qrX, qrY, textX, textY, textWidth, textHeight} = labelLayout(width, height, qr.modules.size);
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
  pdf.addImage(labelText(name, date, textWidth, textHeight), 'PNG', textX, textY, textWidth, textHeight);
  pdf.setProperties({title: name, subject: url, creator: 'Growstuff'});
  return pdf;
}
