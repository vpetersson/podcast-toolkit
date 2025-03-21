#!/bin/bash

# Removed `-c:v hevc_videotoolbox` and
# replaced it with `-c:v libx265` since it
# this (much faster) codec appears to be broken
# on macOS Sequoia, and generates massive files.

mkdir -p mp3 h265

for i in h264/*.mp4; do
    base=$(basename "$i" .mp4)

    if [ ! -f "h265/$base.mp4" ]; then
        echo "Generating h265 for $base."
        ffmpeg \
            -i "$i" \
            -tag:v hvc1 \
            -c:v libx265 \
            -crf 28 \
            -c:a aac \
            -movflags faststart \
            -b:a 128k \
            "h265/$base.mp4"

    fi

    if [ ! -f "mp3/$base.mp3" ]; then
        echo "Generating MP3 for $base."
        ffmpeg \
            -i "$i" \
            -c:a libmp3lame \
            "mp3/$base.mp3"
    fi
done
