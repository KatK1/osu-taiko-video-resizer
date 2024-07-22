#!/bin/sh

on_macOS() {
	if [ "$(uname)" = "Darwin" ] then
		return 0
	else
		return 1
	fi
}

print_usage() {
	echo ""
	echo "Usage: $0 <target_size> <video_file>"
	echo "	target_size: targeted file size in the format VALUE[K/KB/M/MB]"
	echo "	video_file: self explanatory"
	echo "		defaults to cwd/output/output.mp4"
	echo "		if not available, cwd/output.mp4"
	echo ""
	echo "	Examples: $0 4.5M | $0 2400KB video.mp4"
	echo "	NOTE: usually results in files slightly larger than the provided value"
	echo ""
}

check_dependencies() {
	if ! command -v ffmpeg >/dev/null 2>&1; then
		echo "ffmpeg is either not installed or not in the PATH."
		echo "please install ffmpeg to use this script"
		exit 1
	fi

	if ! command -v bc >/dev/null 2>&1; then
		echo "bc is either not installed or not in the PATH."
		echo "please install it before using this script"
		echo "	MAC: brew install bc"
		echo "	ARCH: pacman -S bc"
		echo "	DEBIAN: apt install bc"
		echo "	FEDORA: dnf install bc"
		echo "	NIX: nix-shell -p bc"
		echo "	OTHERS: likely a package called 'bc'"
		echo "	IF NOT AVAILABLE: download a tar.gz: https://www.gnu.org/software/bc/"
		echo "		and place it in a folder in your PATH"
		echo ""
		exit 1
	fi
}

echo ""
echo "bash script made by KatK1"
echo ""
check_dependencies

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
	echo "Invalid amount of arguments."
	print_usage
	exit 1
fi

if [ "$#" -eq 2 ]; then
	INPUT="$2"
elif [ -f "output/output.mp4" ]; then
	INPUT="output/output.mp4"
else
	INPUT="output.mp4"
fi

TARGETSIZE="$1"

if [ ! -f "$INPUT" ]; then
	echo "Video file '$INPUT' not found."
	print_usage
	exit 1
fi

if ! [[ "$TARGETSIZE" =~ ^[0-9]+(\.[0-9]*)?(K|KB|M|MB)$ ]]; then
	echo "Invalid target size format. Should be VALUE[KB/MB], (5MB, 10000K, etc.)"
	print_usage
	exit 1
fi

echo "probing..."
VIDEO_LENGTH=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")

if on_macOS; then
	VIDEO_SIZE=$(stat -f %z "$INPUT")
else
	VIDEO_SIZE=$(stat -c %s "$INPUT")
fi

TARGETSIZE_VALUE=$(echo "$TARGETSIZE" | sed 's/[^0-9.]*//g')
TARGETSIZE_UNIT=$(echo "$TARGETSIZE" | sed 's/[0-9.]*//g')

if [ "$TARGETSIZE_UNIT" = "KB" ] || [ "$TARGETSIZE_UNIT" = "K" ]; then
	TARGETSIZE_BYTES=$(echo "$TARGETSIZE_VALUE * 1024" | bc)
elif [ "$TARGETSIZE_UNIT" = "MB" ] || [ "$TARGETSIZE_UNIT" = "M" ]; then
	TARGETSIZE_BYTES=$(echo "$TARGETSIZE_VALUE * 1024 * 1024" | bc)
else
	echo "Invalid target size unit. Use K/KB or M/MB."
	print_usage
	exit 1
fi

echo "calculating bitrate..."
TARGETRATE=$(echo "scale=2; ($TARGETSIZE_BYTES * 8) / $VIDEO_LENGTH / 1000" | bc -q)
echo "target bitrate: $TARGETRATE kbps"

echo "performing first pass..."
ffmpeg -y -loglevel warning -i "${INPUT}" -c:v libx264 -b:v "${TARGETRATE}k" -pass 1 -an -f mp4 /dev/null && \
echo "performing second pass..."
ffmpeg -y -loglevel warning -i "${INPUT}" -c:v libx264 -b:v "${TARGETRATE}k" -pass 2 -an output/smaller.mp4

if [ $? -eq 0 ]; then
	echo "Encoding completed successfully."
	exit 0
else
	echo "FFmpeg encoding failed."
	exit 1
fi
