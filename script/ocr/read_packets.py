#!/usr/bin/env python3
"""Read the text on photos of seed packets that haven't been read yet.

Takes a list of photos, one JSON object per line, from Growstuff's
`rake packets:needing_ocr` (the photos labelled front or back of a seed packet
whose seed has no text from the packet yet, oldest first). Downloads each one,
runs an OCR command on it, and prints the same object with the text added:

    {"photo_id": "118", "seed_ids": [10], "label": "back", "image_url": "...", "text": "..."}

Progress and errors go to stderr. Nothing is uploaded: for now this only reads.

    bin/rails packets:needing_ocr LIMIT=5 | python3 script/ocr/read_packets.py

or from a saved list:

    bin/rails packets:needing_ocr > photos.jsonl
    python3 script/ocr/read_packets.py --photos photos.jsonl --limit 3 > text.jsonl

    --photos FILE    the list of photos (default: standard input)
    --limit N        read only the first N photos of the list
    --ocr-command    the OCR tool to run on each image, {image} being its path.
                     Default "tesseract {image} stdout"; any command that prints
                     the text works, so other engines can be tried the same way.
    --keep-images D  keep the downloaded images in directory D, to try tools on
    --clean          tidy each image before reading it: for faint, tilted or dark
                     packets that read as nothing (needs Pillow and numpy)

Needs only the python3 standard library, and whatever OCR command is used.
"""

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request


def fetch(url):
    return urllib.request.urlopen(urllib.request.Request(url), timeout=60)


def larger(url):
    """Flickr's `_z` (640px) is too small for packet fine print; `_b` is 1024px."""
    return re.sub(r"_z(\.\w+)$", r"_b\1", url)


def download(url, directory, name):
    for candidate in dict.fromkeys([larger(url), url]):
        try:
            with fetch(candidate) as response:
                path = os.path.join(directory, name + os.path.splitext(candidate)[1])
                with open(path, "wb") as f:
                    f.write(response.read())
                return path, candidate
        except urllib.error.HTTPError:
            continue
    return None, None


def clean(path):
    """Use only the red channel, where dark ink on orange or brown paper has the
    most contrast, divide out the uneven lighting, and double the size."""
    try:
        import numpy
        from PIL import Image, ImageFilter
    except ImportError:
        sys.exit("--clean needs Pillow and numpy: sudo apt install python3-pil python3-numpy")
    red = Image.open(path).convert("RGB").split()[0]
    big = red.resize((red.width * 2, red.height * 2), Image.LANCZOS)
    pixels = numpy.asarray(big).astype("float32")
    lighting = numpy.asarray(big.filter(ImageFilter.GaussianBlur(30))).astype("float32")
    tidy = numpy.clip(pixels / numpy.maximum(lighting, 1) * 200, 0, 255).astype("uint8")
    cleaned = os.path.splitext(path)[0] + "-clean.png"
    Image.fromarray(tidy).save(cleaned)
    return cleaned


def ocr(command, path):
    arguments = [part.replace("{image}", path) for part in shlex.split(command)]
    return subprocess.run(arguments, capture_output=True, text=True, check=True).stdout


def read_photos(source):
    for number, line in enumerate(source, 1):
        if line.strip():
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                sys.exit(f"Line {number} of the list of photos is not JSON: {line.strip()[:80]}")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--photos", metavar="FILE", help="the list of photos, one JSON object per line (default: stdin)")
    parser.add_argument("--limit", "-n", type=int, help="read only the first N photos of the list")
    parser.add_argument("--ocr-command", default="tesseract {image} stdout")
    parser.add_argument("--keep-images", metavar="DIR", help="keep the downloaded images in this directory")
    parser.add_argument("--clean", action="store_true", help="tidy each image before reading it")
    args = parser.parse_args()

    if args.limit is not None and args.limit < 1:
        sys.exit("--limit must be at least 1.")
    if args.photos is None and sys.stdin.isatty():
        sys.exit("Give it a list of photos: bin/rails packets:needing_ocr | python3 script/ocr/read_packets.py")
    if args.keep_images:
        os.makedirs(args.keep_images, exist_ok=True)

    source = open(args.photos) if args.photos else sys.stdin
    count = 0
    for photo in read_photos(source):
        if args.limit is not None and count >= args.limit:
            break
        count += 1
        with tempfile.TemporaryDirectory() as scratch:
            directory = args.keep_images or scratch
            path, used_url = download(photo["image_url"], directory, f"photo-{photo['photo_id']}")
            if path is None:
                print(f"photo {photo['photo_id']}: could not download {photo['image_url']}", file=sys.stderr)
                continue
            try:
                text = ocr(args.ocr_command, clean(path) if args.clean else path)
            except (OSError, subprocess.CalledProcessError) as error:
                sys.exit(f"The OCR command failed on photo {photo['photo_id']}: {error}")
        print(json.dumps({**photo, "image_url": used_url, "text": text}), flush=True)
        print(f"photo {photo['photo_id']} ({photo.get('label')}): {len(text.split())} words", file=sys.stderr)
    print(f"{count} photo(s) read.", file=sys.stderr)


if __name__ == "__main__":
    main()
