// Gets a photo of a packet ready for OCR. Packets are small print on coloured
// paper, which Tesseract reads badly as it is. Two things fix most of that: use
// only the red channel (dark ink on orange or brown paper has the most contrast
// there), and divide out the uneven lighting. Then twice the size, as the print
// is small.

// Flickr's 640px size is too small to read the fine print; its 1024px one is not.
export function largerFlickrUrl(url) {
  return url.replace(/_z(\.\w+)$/, '_b$1');
}

function loadImage(url) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.crossOrigin = 'anonymous'; // so the canvas can be read back
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error(`Could not load ${url}`));
    image.src = url;
  });
}

export async function loadPacketImage(url) {
  for (const candidate of new Set([largerFlickrUrl(url), url])) {
    try {
      return await loadImage(candidate);
    } catch (error) {
      // fall back to the address we were given
    }
  }
  throw new Error(`Could not load ${url}`);
}

function canvasOf(width, height) {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  return canvas;
}

export function cleanForOcr(image, { scale = 2, blurFactor = 16 } = {}) {
  const width = Math.round(image.naturalWidth * scale);
  const height = Math.round(image.naturalHeight * scale);
  const canvas = canvasOf(width, height);
  const context = canvas.getContext('2d', { willReadFrequently: true });
  context.imageSmoothingQuality = 'high';
  context.drawImage(image, 0, 0, width, height);

  const pixels = context.getImageData(0, 0, width, height);
  const data = pixels.data;
  const red = new Uint8ClampedArray(width * height);
  for (let i = 0; i < red.length; i++) {
    red[i] = data[i * 4];
    data[i * 4 + 1] = data[i * 4 + 2] = red[i];
  }
  context.putImageData(pixels, 0, 0);

  // The lighting is the picture shrunk a long way and blown back up: a blur.
  const small = canvasOf(Math.max(1, Math.round(width / blurFactor)), Math.max(1, Math.round(height / blurFactor)));
  small.getContext('2d').drawImage(canvas, 0, 0, small.width, small.height);
  context.drawImage(small, 0, 0, width, height);
  const lighting = context.getImageData(0, 0, width, height).data;

  for (let i = 0; i < red.length; i++) {
    const value = Math.min(255, (red[i] / Math.max(lighting[i * 4], 1)) * 200);
    data[i * 4] = data[i * 4 + 1] = data[i * 4 + 2] = value;
    data[i * 4 + 3] = 255;
  }
  context.putImageData(pixels, 0, 0);
  return canvas;
}
