#!/bin/sh

CONFIG_DIR="$HOME/.config/KatK1"
CONFIG_FILE="$CONFIG_DIR/resize.conf"
. $CONFIG_FILE

if ! [ -z "$1" ]; then
	TARGETSIZE_BYTES=$(echo "$1 * 1000" | bc -q)
else
	TARGETSIZE_BYTES=$(echo "$preferred_size * 1000" | bc -q)
fi

check_macOS() {
	if [ "$(uname)" = "Darwin" ]; then
		macOS=1
	else
		macOS=0
	fi
}

if ! [ -f "$output_dir/pre-scale.mp4" ]; then
	echo "pre-scale.mp4 not found, exitting without scaling..."
	exit 1
fi

INPUT="$output_dir/pre-scale.mp4"

VIDEO_LENGTH=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")

check_macOS
if [ $macOS = 1 ]; then
	VIDEO_SIZE=$(stat -f %z "$INPUT")
else
	VIDEO_SIZE=$(stat -c %s "$INPUT")
fi

if [[ $VIDEO_SIZE -le $TARGETSIZE_BYTES ]]; then
	echo "target size would result in a larger video file, exitting without scaling."
	exit 0
fi

echo "calculating bitrate..."
TARGETRATE=$(echo "scale=0; ($TARGETSIZE_BYTES * 8) / $VIDEO_LENGTH / 1000" | bc -q)
echo "target bitrate: $TARGETRATE kbps"

echo "performing first pass..."
ffmpeg -y -loglevel warning -i "${INPUT}" -c:v libx264 -b:v "${TARGETRATE}k" -pass 1 -an -f mp4 /dev/null && \
echo "performing second pass..."
ffmpeg -y -loglevel warning -i "${INPUT}" -c:v libx264 -b:v "${TARGETRATE}k" -pass 2 -an $output_dir/final.mp4

if [ $macOS = 1 ]; then
	END_SIZE=$(stat -f %z "$output_dir/final.mp4")
else
	END_SIZE=$(stat -c %s "$output_dir/final.mp4")
fi

if [ $END_SIZE -gt $VIDEO_SIZE ]; then
	rm "$output_dir/final.mp4"
	echo "resized video was larger than original, exitting without resizing.."
	exit 1
fi

if [ $? = 0 ]; then
	echo "Encoding completed successfully."
	exit 0
else
	echo "FFmpeg encoding failed."
	exit 1
fi
