#!/usr/bin/env python3
"""Read the text on photos of seed packets that haven't been read yet, and save it.

Asks a Growstuff server's API for the seeds whose packet photos (labelled front
or back) have not been read yet, oldest first. For each seed it downloads those
photos, runs an OCR command on each, joins the text (front, then back) and, with
--upload, saves it on the seed. Without --upload nothing is saved: it only shows
what it would save.

    GROWSTUFF_URL=http://localhost:3000 script/ocr/read_packets.py --limit 5
    GROWSTUFF_API_TOKEN=... script/ocr/read_packets.py --limit 5 --upload

One JSON object per seed goes to stdout, with what happened to it:

    {"seed_id": "10", "photo_ids": ["118"], "words": 40, "action": "would save", "text": "..."}

Progress and errors go to stderr.

    GROWSTUFF_URL        the server (default https://www.growstuff.org)
    GROWSTUFF_API_TOKEN  the API token of an admin (Settings > Apps). Only
                         --upload needs it; reading is public.

    --limit N        read only the first N seeds (the oldest that need it)
    --upload         save the text on each seed (otherwise only show it)
    --list           only list the photos that need reading, without reading them
    --min-words N    don't save less than N real-looking words (default 3). Seeds
                     with less are remembered as tried, and skipped next time
    --retry-tried    read the seeds remembered as tried too (use after changing the
                     OCR tool or settings)
    --state FILE     where tried seeds are remembered (default ~/.growstuff-packet-ocr.json)
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
DEFAULT_STATE = os.path.join(os.path.expanduser("~"), ".growstuff-packet-ocr.json")
PAGE_SIZE = 100  # the most the API gives in a page
JSON_API = "application/vnd.api+json"


def fetch(url, token=None, accept=None):
    request = urllib.request.Request(url)
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    if accept:
        request.add_header("Accept", accept)
    return urllib.request.urlopen(request, timeout=60)


def get_json(url, token=None):
    with fetch(url, token, JSON_API) as response:
        return json.load(response)


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
        page = get_json(f"{base_url}/api/v1/photos?{query}", token)
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


def packet_photos_of(base_url, token, seed_id):
    """All of a seed's photos of its packet, front first, so the text reads in order."""
    query = urllib.parse.urlencode({"filter[seed_id]": seed_id, "page[size]": PAGE_SIZE})
    photos = [
        {"photo_id": photo["id"], "label": photo["attributes"]["label"], "image_url": photo["attributes"]["fullsize-url"]}
        for photo in get_json(f"{base_url}/api/v1/photos?{query}", token)["data"]
        if photo["attributes"]["label"]
    ]
    return sorted(photos, key=lambda photo: (photo["label"] != "front", int(photo["photo_id"])))


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
        return path
    return None


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


def read_photo(photo, args):
    """The text of one photo, or None if it could not be downloaded."""
    with tempfile.TemporaryDirectory() as scratch:
        path = download(photo["image_url"], args.keep_images or scratch, f"photo-{photo['photo_id']}")
        if path is None:
            return None
        try:
            return ocr(args.ocr_command, clean(path) if args.clean else path)
        except (OSError, subprocess.CalledProcessError) as error:
            sys.exit(f"The OCR command failed on photo {photo['photo_id']}: {error}")


def real_words(text):
    """Words with at least three letters: what a stray mark or a speck is not."""
    return sum(1 for word in text.split() if sum(char.isalpha() for char in word) >= 3)


def tidy(text):
    """The lines worth keeping: those with at least two letters or digits. The
    edges of a photo read as columns of single marks, which are not text."""
    lines = [line.strip() for line in text.splitlines()]
    return "\n".join(line for line in lines if sum(char.isalnum() for char in line) >= 2)


def combine(parts):
    """The text of a seed's photos as one, each marked with its side."""
    return "\n\n".join(f"[{label}]\n{tidy(text)}" for label, text in parts if tidy(text))


def save_text(base_url, token, seed_id, text):
    body = {"data": {"type": "seeds", "id": str(seed_id), "attributes": {"packet-text": text}}}
    request = urllib.request.Request(
        f"{base_url}/api/v1/seeds/{seed_id}", data=json.dumps(body).encode(), method="PATCH"
    )
    request.add_header("Content-Type", JSON_API)
    request.add_header("Accept", JSON_API)
    request.add_header("Authorization", f"Bearer {token}")
    urllib.request.urlopen(request, timeout=60).close()


def load_tried(path, base_url):
    try:
        with open(path) as f:
            return set(json.load(f).get(base_url, {}).get("tried_seeds", []))
    except (OSError, ValueError):
        return set()


def remember_tried(path, base_url, seed_ids):
    try:
        with open(path) as f:
            state = json.load(f)
    except (OSError, ValueError):
        state = {}
    state.setdefault(base_url, {})["tried_seeds"] = sorted(seed_ids, key=int)
    with open(path, "w") as f:
        json.dump(state, f, indent=2)


def read_seed(base_url, token, seed_id, args):
    """Read all of a seed's packet photos. Returns (photo ids, text) or (photo ids, None)
    if one could not be downloaded, as saving only some of a seed's text would leave
    the rest to be forgotten."""
    photos = packet_photos_of(base_url, token, seed_id)
    parts = []
    for photo in photos:
        text = read_photo(photo, args)
        if text is None:
            print(f"photo {photo['photo_id']}: could not download {photo['image_url']}", file=sys.stderr)
            return [p["photo_id"] for p in photos], None
        print(f"photo {photo['photo_id']} ({photo['label']}): {real_words(text)} words", file=sys.stderr)
        parts.append((photo["label"], text))
    return [p["photo_id"] for p in photos], combine(parts)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--base-url", default=os.environ.get("GROWSTUFF_URL", DEFAULT_URL))
    parser.add_argument("--limit", "-n", type=int, help="read only the first N seeds (the oldest)")
    parser.add_argument("--upload", action="store_true", help="save the text on each seed")
    parser.add_argument("--list", action="store_true", help="list the photos that need reading, without reading them")
    parser.add_argument("--min-words", type=int, default=3, help="the least real-looking words worth saving")
    parser.add_argument("--retry-tried", action="store_true", help="read the seeds remembered as tried too")
    parser.add_argument("--state", default=DEFAULT_STATE, help="where tried seeds are remembered")
    parser.add_argument("--ocr-command", default="tesseract {image} stdout")
    parser.add_argument("--keep-images", metavar="DIR", help="keep the downloaded images in this directory")
    parser.add_argument("--clean", action="store_true", help="tidy each image before reading it")
    args = parser.parse_args()

    if args.limit is not None and args.limit < 1:
        sys.exit("--limit must be at least 1.")
    base_url = args.base_url.rstrip("/")
    token = os.environ.get("GROWSTUFF_API_TOKEN")
    if args.upload and not token:
        sys.exit("--upload needs GROWSTUFF_API_TOKEN: the API token of an admin (Settings > Apps).")
    if args.keep_images:
        os.makedirs(args.keep_images, exist_ok=True)

    print(f"Server: {base_url}", file=sys.stderr)
    try:
        if args.list:
            count = 0
            for photo in photos_needing_ocr(base_url, token, args.limit):
                count += 1
                print(json.dumps(photo), flush=True)
            print(f"{count} photo(s) listed.", file=sys.stderr)
            return
        run(base_url, token, args)
    except urllib.error.HTTPError as error:
        sys.exit(f"The server said {error.code} {error.reason} for {error.url}")
    except (urllib.error.URLError, TimeoutError) as error:
        sys.exit(f"Could not reach {base_url}: {getattr(error, 'reason', error)}")


def seeds_to_read(base_url, token, args):
    """The seeds with unread packet photos, oldest first, less any tried before. The
    whole waiting list is fetched first: seeds saved partway through would drop off
    it, and shift the pages not yet asked for."""
    tried = set() if args.retry_tried else load_tried(args.state, base_url)
    seed_ids = []
    for photo in photos_needing_ocr(base_url, token):
        seed_ids += [seed_id for seed_id in photo["seed_ids"] if seed_id not in seed_ids and seed_id not in tried]
    return seed_ids[: args.limit]


def run(base_url, token, args):
    remembered = load_tried(args.state, base_url)
    seed_ids = seeds_to_read(base_url, token, args)
    saved = 0
    for seed_id in seed_ids:
        photo_ids, text = read_seed(base_url, token, seed_id, args)
        result = {"seed_id": seed_id, "photo_ids": photo_ids}
        if text is None:
            result["action"] = "could not download a photo"
        elif real_words(text) < args.min_words:
            result.update(words=real_words(text), action="too little text, not saved")
            remembered.add(seed_id)
        else:
            result.update(words=real_words(text), text=text, action="would save")
            if args.upload:
                try:
                    save_text(base_url, token, seed_id, text)
                    result["action"] = "saved"
                    saved += 1
                except urllib.error.HTTPError as error:
                    if error.code in (401, 403):
                        sys.exit(f"The server refused to save (HTTP {error.code}): is the token an admin's?")
                    result["action"] = f"not saved: HTTP {error.code}"
        print(json.dumps(result), flush=True)
    if args.upload:
        remember_tried(args.state, base_url, remembered)
    outcome = f"{saved} saved" if args.upload else "nothing saved without --upload"
    print(f"{len(seed_ids)} seed(s) read, {outcome}.", file=sys.stderr)


if __name__ == "__main__":
    main()
