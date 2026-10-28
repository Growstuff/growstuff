#!/usr/bin/env python3
"""Read the text on photos of seed packets that haven't been read yet.

Asks a Growstuff server's API for the photos labelled front or back of a seed
packet whose seed has no text from the packet yet, oldest first. Downloads each
one, runs an OCR command on it, and prints one JSON object per photo on stdout:

    {"photo_id": "118", "seed_ids": ["10"], "label": "back", "image_url": "...", "text": "..."}

Progress and errors go to stderr. Nothing is uploaded: for now this only reads.

The server comes from the environment, so the same command works against dev or
production:

    GROWSTUFF_URL=http://localhost:3000 script/ocr/read_packets.py --limit 5

    GROWSTUFF_URL        the server (default https://www.growstuff.org)
    GROWSTUFF_API_TOKEN  an API token, sent if set. Reading doesn't need one;
                         saving the text will.

    --limit N        read only the first N photos (the oldest that need it)
    --list           only list the photos that need reading, without reading them
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
import urllib.parse
import urllib.request

DEFAULT_URL = "https://www.growstuff.org"
PAGE_SIZE = 100  # the most the API gives in a page


def fetch(url, token=None, accept=None):
    request = urllib.request.Request(url)
    if token:
        request.add_header("Authorization", f"Token token={token}")
    if accept:
        request.add_header("Accept", accept)
    return urllib.request.urlopen(request, timeout=60)


def photos_needing_ocr(base_url, token, limit=None):
    """Yield the photos of seed packets with no text yet, oldest first.

    Pages are asked for by number, not by following the API's own links, which
    point at the address the API is configured with and not necessarily at this
    server."""
    size = min(limit or PAGE_SIZE, PAGE_SIZE)
    count = 0
    for number in range(1, 10_000):
        query = urllib.parse.urlencode(
            {"filter[needs_ocr]": "true", "include": "seeds", "page[size]": size, "page[number]": number}
        )
        with fetch(f"{base_url}/api/v1/photos?{query}", token, "application/vnd.api+json") as response:
            page = json.load(response)
        for photo in page["data"]:
            if limit is not None and count >= limit:
                return
            count += 1
            seeds = (photo.get("relationships", {}).get("seeds") or {}).get("data") or []
            yield {
                "photo_id": photo["id"],
                "seed_ids": [seed["id"] for seed in seeds],
                "label": photo["attributes"]["label"],
                "image_url": photo["attributes"]["fullsize-url"],
            }
        if len(page["data"]) < size:
            return


def larger(url):
    """Flickr's `_z` (640px) is too small for packet fine print; `_b` is 1024px."""
    return re.sub(r"_z(\.\w+)$", r"_b\1", url)


def download(url, directory, name):
    for candidate in dict.fromkeys([larger(url), url]):
        try:
            with fetch(candidate) as response:
                image = response.read()
        except (urllib.error.URLError, TimeoutError):  # HTTP errors are URLErrors too
            continue
        path = os.path.join(directory, name + os.path.splitext(candidate)[1])
        with open(path, "wb") as f:
            f.write(image)
        return path, candidate
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


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--base-url", default=os.environ.get("GROWSTUFF_URL", DEFAULT_URL))
    parser.add_argument("--limit", "-n", type=int, help="read only the first N photos (the oldest)")
    parser.add_argument("--list", action="store_true", help="list the photos that need reading, without reading them")
    parser.add_argument("--ocr-command", default="tesseract {image} stdout")
    parser.add_argument("--keep-images", metavar="DIR", help="keep the downloaded images in this directory")
    parser.add_argument("--clean", action="store_true", help="tidy each image before reading it")
    args = parser.parse_args()

    if args.limit is not None and args.limit < 1:
        sys.exit("--limit must be at least 1.")
    if args.keep_images:
        os.makedirs(args.keep_images, exist_ok=True)

    base_url = args.base_url.rstrip("/")
    token = os.environ.get("GROWSTUFF_API_TOKEN")
    print(f"Server: {base_url}", file=sys.stderr)
    count = 0
    try:
        for photo in photos_needing_ocr(base_url, token, args.limit):
            count += 1
            if args.list:
                print(json.dumps(photo), flush=True)
                continue
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
            print(f"photo {photo['photo_id']} ({photo['label']}): {len(text.split())} words", file=sys.stderr)
    except urllib.error.HTTPError as error:
        sys.exit(f"The server said {error.code} {error.reason} for {error.url}")
    except (urllib.error.URLError, TimeoutError) as error:
        sys.exit(f"Could not reach {base_url}: {getattr(error, 'reason', error)}")
    print(f"{count} photo(s) {'listed' if args.list else 'read'}.", file=sys.stderr)


if __name__ == "__main__":
    main()
