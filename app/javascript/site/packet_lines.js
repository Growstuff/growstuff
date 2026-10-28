// Tesseract reads a photo as lines of text, each with how sure it is. On a
// packet the real lines score well, and the rest, such as the leaves in a
// picture of a cabbage read as letters, score badly. Reading the photo at more
// than one size suits both big lettering and small print, so the readings are
// merged: low-confidence lines dropped, and of those that read the same row of
// the photo, the more confident one kept.

export const MIN_CONFIDENCE = 55;

// Whether a line is mostly letters and digits, not a scatter of marks.
function looksLikeWords(text) {
  const alphanumeric = (text.match(/[A-Za-z0-9]/g) || []).length;
  return alphanumeric >= 3 && alphanumeric / text.length >= 0.5;
}

// How much of the shorter line's height is shared with the other's.
function overlap(a, b) {
  const shared = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top);
  return shared <= 0 ? 0 : shared / Math.min(a.bottom - a.top, b.bottom - b.top);
}

// The lines of one reading, as {text, confidence, top, bottom}, with the rows
// measured on the photo itself and not on the enlarged copy that was read.
export function linesOf(result, scale) {
  const lines = (result.blocks || []).flatMap((block) => block.paragraphs.flatMap((paragraph) => paragraph.lines));
  return lines.map((line) => ({
    text: line.text.trim(),
    confidence: line.confidence,
    top: line.bbox.y0 / scale,
    bottom: line.bbox.y1 / scale,
  }));
}

// The text of several readings of the same photo, top to bottom.
export function mergeLines(readings, minConfidence = MIN_CONFIDENCE) {
  const sure = readings.flat()
    .filter((line) => line.confidence >= minConfidence && looksLikeWords(line.text))
    .sort((a, b) => b.confidence - a.confidence);
  const kept = [];
  sure.forEach((line) => {
    if (!kept.some((other) => overlap(other, line) > 0.5)) kept.push(line);
  });
  return kept.sort((a, b) => a.top - b.top).map((line) => line.text).join('\n');
}
