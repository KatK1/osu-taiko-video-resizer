#!/bin/sh

CONFIG_DIR="$HOME/.config/KatK1"
CONFIG_FILE="$CONFIG_DIR/resize.conf"
valid_int=0
SINGLE_SIZE=0

check_int() {
	local re="^[0-9]+$"
	if [[ $preferred_size =~ $re ]] && [[ $preferred_size -gt 0 ]]; then
		echo "(debug) new default size: $preferred_size"
		valid_int=1
		return 0
	fi

	echo "this value must be an integer, please try again"
	valid_int=0
	return 1
}

make_config() {
	echo "no config file found, creating one..."
	echo "please enter your desired options:"
	read -p "assets directory (black.png and deflate.sh): " assets_dir
	read -p "output directory (no files required): " -i "$HOME" output_dir
	
	until [[ valid_int = 1 ]]; do
		read -p "automatically resize video to desired size (KB): " preferred_size
		check_int
	done
	
	if ! [ -d "$CONFIG_DIR" ]; then
		mkdir "$CONFIG_DIR"
	fi

	echo "assets_dir=$assets_dir" > "$CONFIG_FILE"
	echo "output_dir=$output_dir" >> "$CONFIG_FILE"
	echo "preferred_size=$preferred_size" >> "$CONFIG_FILE"
	echo "config file successfully created at $CONFIG_FILE"
}

check_config() {
	. $CONFIG_FILE
	for var in assets_dir output_dir preferred_size; do
		echo "(debug) value of $var is ${!var}"
	done
}

check_dependencies() {
	if ! command -v ffmpeg >/dev/null 2>&1; then
		echo "ffmpeg is either not installed or not in the PATH."
		echo "please install ffmpeg to use this script"
		exit 1
	fi

	if ! command -v bc -q >/dev/null 2>&1; then
		echo "bc is either not installed or not in the PATH."
		echo "please install bc in order to specify a target size"
		echo ""
		has_bc=0
	else
		has_bc=1
	fi
}

echo ""
echo "bash script made by KatK1, adapted from a tool by Khoo Hao Yit and Jerry"
echo ""
check_dependencies

if ! [ -f "$CONFIG_FILE" ]; then
	make_config
fi

check_config

if [ -z "$1" ]; then
	echo "no file provided"
	echo "please run as \"resize.sh /path/to/video/file\""
	echo "if the path contains spaces, surround it with ' symbol"
	exit 1
fi

if ! [ -z "$2" ]; then
	SINGLE_SIZE="$2"
fi

if ! [ -f "$assets_dir/black.png" ]; then
	echo "missing assets (black.png): can not generate video"
	exit 1
fi

echo "encoding in progress, please wait..."
ffmpeg -y -loglevel warning -i "$1" -i $assets_dir/black.png -c:v libx264 -filter_complex "\
	[0:v]split=3[blur][scale][output]; \
	[output]scale=1280:720[output]; \
	[scale]scale=-1:340[scale]; \
	[blur]scale=1280:-1,boxblur=10,crop=1280:340[blur]; \
	[output][1]overlay=0:0[output]; \
	[output][blur]overlay=0:387[output]; \
	[output][scale]overlay='(W-w)/2:387'[output]" \
	-map "[output]" -aspect 1280:720 -an $output_dir/pre-scale.mp4

if ! [ $? = 0 ]; then
	echo ""
	echo "ffmpeg error: is the specified file a valid video file, or missing assets?"
	exit 1
fi

echo "video conversion completed, attempting to resize..."

if ! [ -f "$assets_dir/deflate.sh" ]; then
	echo "missing assets (deflate.sh): can not reduce video to desired size"
	exit 1
else
	if [ $has_bc = 1 ]; then
		echo ""
		echo "NOTE: final size is usually slightly larger than the specified size"
		echo "      if it's too big still, you can run $assets_dir/deflate.sh SIZE"
		echo "      to regenerate the final video, with a new target size of SIZE (KB)"
		echo ""
		if [ $SINGLE_SIZE -gt 0 ]; then
			$assets_dir/deflate.sh $SINGLE_SIZE
		else
			$assets_dir/deflate.sh
		fi
	else
		echo "because bc is not installed, exitting without reducing video size"
		exit 1
	fi
fi

exit 0
