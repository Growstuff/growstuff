# Runs read_packets.py with what it needs: Python, the tesseract OCR program (the
# Debian package tesseract-ocr, which includes the English data), and Pillow and
# numpy for --clean.
#
#   docker build -t growstuff-packet-ocr script/ocr
#
# Everything it keeps (the seeds it has tried, and images if asked) is in /data,
# so give it somewhere to keep them. Docker installed as a snap can only share
# folders under your home directory, so use one there:
#
#   docker run --rm -v "$HOME/packet-ocr:/data" growstuff-packet-ocr --list
#   docker run --rm -v "$HOME/packet-ocr:/data" growstuff-packet-ocr --limit 5 --clean
#   docker run --rm -v "$HOME/packet-ocr:/data" -e GROWSTUFF_API_TOKEN \
#     growstuff-packet-ocr --limit 5 --clean --upload
#
# It reads https://www.growstuff.org unless told otherwise. For a Growstuff running
# on this machine, add --network host -e GROWSTUFF_URL=http://localhost:3000.
FROM python:3.13-slim-trixie

RUN apt-get update \
    && apt-get install -y --no-install-recommends tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Not root. Uid 1000 is the usual first user, so a folder mounted at /data is theirs to write to.
RUN useradd --create-home --home-dir /data --uid 1000 ocr
COPY read_packets.py /app/read_packets.py

USER ocr
ENV HOME=/data
WORKDIR /data
ENTRYPOINT ["python3", "/app/read_packets.py"]
