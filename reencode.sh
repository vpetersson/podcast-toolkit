#!/usr/bin/env bash

# Re-encodes H.264 source files into H.265 (HEVC) and MP3.
#
# Two encoders are supported, selected via the ENCODER env var:
#
#   ENCODER=libx265       (default) — software encoder. Slower, but
#                         produces ~25-35% smaller files than the
#                         hardware path at equivalent perceptual
#                         quality. The right choice when output is
#                         downloaded many times: byte savings at
#                         encode time are paid back at every download.
#                         Tunable via CRF (default 26) and X265_PRESET
#                         (default "slow").
#
#   ENCODER=videotoolbox  Apple's hardware HEVC encoder. Much faster
#                         (uses the Media Engine on Apple Silicon) but
#                         lower compression efficiency. On recent macOS
#                         (Sequoia+) it must have explicit rate control
#                         or it produces gibberish/oversized output; we
#                         pin it to constant-quality mode via -q:v.
#                         Tunable via HEVC_QUALITY (default 65, 1..100,
#                         higher = better).
#
# Resolution and framerate are passed through unchanged. Output is
# 8-bit 4:2:0 H.265 in an MP4 container with the hvc1 tag and
# faststart, which is the most broadly playable HEVC profile.

set -euo pipefail

readonly INPUT_DIR="h264"
readonly VIDEO_OUT_DIR="h265"
readonly AUDIO_OUT_DIR="mp3"

readonly ENCODER="${ENCODER:-libx265}"
readonly CRF="${CRF:-26}"
readonly X265_PRESET="${X265_PRESET:-slow}"
readonly HEVC_QUALITY="${HEVC_QUALITY:-65}"
readonly AAC_BITRATE="${AAC_BITRATE:-96k}"
readonly MP3_BITRATE="${MP3_BITRATE:-128k}"

command -v ffmpeg >/dev/null 2>&1 || {
    echo "error: ffmpeg not found in PATH" >&2
    exit 1
}

case "$ENCODER" in
    libx265)
        video_opts=(
            -c:v libx265
            -preset "$X265_PRESET"
            -crf "$CRF"
            -x265-params log-level=error
        )
        encoder_label="libx265 crf=$CRF preset=$X265_PRESET"
        ;;
    videotoolbox)
        video_opts=(
            -c:v hevc_videotoolbox
            -q:v "$HEVC_QUALITY"
            -profile:v main
            -allow_sw 1
        )
        encoder_label="hevc_videotoolbox q:v=$HEVC_QUALITY"
        ;;
    *)
        echo "error: unknown ENCODER '$ENCODER' (expected 'libx265' or 'videotoolbox')" >&2
        exit 1
        ;;
esac

if [ ! -d "$INPUT_DIR" ]; then
    echo "error: input directory '$INPUT_DIR' does not exist" >&2
    exit 1
fi

mkdir -p "$VIDEO_OUT_DIR" "$AUDIO_OUT_DIR"

shopt -s nullglob
inputs=("$INPUT_DIR"/*.mp4)
shopt -u nullglob

if [ ${#inputs[@]} -eq 0 ]; then
    echo "no .mp4 files found in $INPUT_DIR/"
    exit 0
fi

for input in "${inputs[@]}"; do
    base=$(basename "$input" .mp4)
    h265_out="$VIDEO_OUT_DIR/$base.mp4"
    mp3_out="$AUDIO_OUT_DIR/$base.mp3"

    if [ ! -f "$h265_out" ]; then
        echo "Encoding H.265 ($encoder_label) for $base..."
        ffmpeg -hide_banner -loglevel error -stats \
            -i "$input" \
            "${video_opts[@]}" \
            -pix_fmt yuv420p \
            -tag:v hvc1 \
            -c:a aac \
            -b:a "$AAC_BITRATE" \
            -movflags +faststart \
            "$h265_out"
    fi

    if [ ! -f "$mp3_out" ]; then
        echo "Encoding MP3 for $base..."
        ffmpeg -hide_banner -loglevel error -stats \
            -i "$input" \
            -vn \
            -c:a libmp3lame \
            -b:a "$MP3_BITRATE" \
            "$mp3_out"
    fi
done
