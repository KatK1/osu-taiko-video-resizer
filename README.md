# osu-taiko-video-resizer
Linux/macOS scripts to resize videos made for use in osu!taiko mapping

### to use:
1. make sure you have an `assets` folder with `deflate.sh` and `black.png` in it, and a desired directory already made to put outputs in (e.g. `~/Videos/resized`
2. (OPTIONAL) you can run `resize.sh` without any arguments to only run the first-time config setup and exit
3. run `resize.sh <video_path>` or `resize.sh <video_path> <desired_size_overwrite>` (desired_size_overwrite should be in KB without any symbols)
4. in the specified output folder, the file `pre-scale.mp4` will be made, and if the settings are set properly, `final.mp4` will be the resized video

if you need to resize the video again, you can run `deflate.sh` or `deflate.sh <size_overwrite>` directly, which will automatically resize `$output_dir/pre-scale.mp4` with the new settings 
if you ever want to change your settings, you can edit the config file manually at `~/.config/KatK1/resize.conf` or delete it and run the script again to run the first-time setup
