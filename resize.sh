#!/bin/sh

check_dependencies() {
	if ! command -v ffmpeg >/dev/null 2>&1; then
		echo "ffmpeg is either not installed or not in the PATH."
		echo "please install ffmpeg to use this script"
		exit 1
	fi
}

echo ""
echo "bash script made by KatK1, adapted from a tool by Khoo Hao Yit and Jerry"
echo ""
check_dependencies

if [ -z "$1" ]; then
	echo "No file provided."
	echo "please call with \"taiko-video-resize.sh /path/to/video/file\""
	echo "if the path contains spaces, surround it like '/path/to/video file'"
	exit 1
fi

echo "encoding in progress, please wait..."
ffmpeg -y -loglevel warning -i "$1" -i assets/black.png -c:v libx264 -filter_complex "\
	[0:v]split=3[blur][scale][output]; \
	[output]scale=1280:720[output]; \
	[scale]scale=-1:340[scale]; \
	[blur]scale=1280:-1,boxblur=10,crop=1280:340[blur]; \
	[output][1]overlay=0:0[output]; \
	[output][blur]overlay=0:387[output]; \
	[output][scale]overlay='(W-w)/2:387'[output]" \
	-map "[output]" -aspect 1280:720 -an output/output.mp4

if [ $? -ne 0 ]; then
	echo ""
	echo "ffmpeg error: is the specified file a valid video file?"
	exit 1
fi

echo "Video conversion completed."
exit 0
